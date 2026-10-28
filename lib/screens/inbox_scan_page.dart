import 'package:flutter/material.dart';

import 'package:expensetracker_reloaded/routes/app_routes.dart';
import 'package:expensetracker_reloaded/services/sms_service.dart';
import 'package:expensetracker_reloaded/utils/money.dart';

/// Controlled SMS inbox import (bugs #12, #13).
///
/// Flow: explain + pick a range -> Start -> progress with Cancel -> summary.
/// Nothing is read until the user taps Start. The scan is marked done only
/// when it finishes; Cancel or an error leaves it available to run again.
/// Reached from onboarding (when "Import past SMS" is on) and from
/// Settings > SMS & Permissions > Scan SMS inbox.
class InboxScanPage extends StatefulWidget {
  const InboxScanPage({super.key, this.fromOnboarding = false, this.scanner});

  /// After onboarding, leaving this page lands on Home instead of popping.
  final bool fromOnboarding;

  /// Test hook; defaults to [SmsService.scanInbox].
  @visibleForTesting
  final Future<ImportSummary> Function(
    Duration window, {
    void Function(int done, int total)? onProgress,
    ImportCancelToken? cancel,
  })?
  scanner;

  /// Range choices shown to the user.
  static const ranges = <String, Duration>{
    '30 days': Duration(days: 30),
    '90 days': Duration(days: 90),
    '180 days': Duration(days: 180),
    '1 year': Duration(days: 365),
  };

  @override
  State<InboxScanPage> createState() => _InboxScanPageState();
}

enum _Stage { consent, scanning, done, failed }

class _InboxScanPageState extends State<InboxScanPage> {
  _Stage _stage = _Stage.consent;
  String _range = '180 days';
  int _done = 0;
  int _total = 0;
  ImportSummary? _summary;
  String? _error;
  ImportCancelToken? _cancel;

  Future<void> _start() async {
    final cancel = ImportCancelToken();
    setState(() {
      _stage = _Stage.scanning;
      _done = 0;
      _total = 0;
      _cancel = cancel;
      _error = null;
    });
    final scan = widget.scanner ?? SmsService.scanInbox;
    try {
      final s = await scan(
        InboxScanPage.ranges[_range]!,
        onProgress: (d, t) {
          if (mounted) {
            setState(() {
              _done = d;
              _total = t;
            });
          }
        },
        cancel: cancel,
      );
      if (!mounted) return;
      setState(() {
        _summary = s;
        _stage = _Stage.done;
      });
    } catch (e) {
      debugPrint('InboxScanPage: scan failed: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _stage = _Stage.failed;
      });
    }
  }

  void _leave({bool openReview = false}) {
    final nav = Navigator.of(context);
    if (widget.fromOnboarding) {
      nav.pushNamedAndRemoveUntil(AppRoutes.home, (r) => false);
      if (openReview) nav.pushNamed(AppRoutes.review);
    } else if (openReview) {
      nav.pushReplacementNamed(AppRoutes.review);
    } else {
      nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Don't let Back silently abandon a running scan; ask to cancel.
      canPop: _stage != _Stage.scanning,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _stage == _Stage.scanning) _cancel?.cancelled = true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan SMS inbox'),
          automaticallyImplyLeading: !widget.fromOnboarding,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: switch (_stage) {
              _Stage.consent => _consent(context),
              _Stage.scanning => _scanning(context),
              _Stage.done => _result(context),
              _Stage.failed => _failed(context),
            },
          ),
        ),
      ),
    );
  }

  Widget _consent(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        Icon(Icons.manage_search, size: 56, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'Find past transactions',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Ledgerly will read bank and UPI messages in your SMS inbox on this '
          'phone and add the transactions it finds. Nothing is uploaded.\n\n'
          'Unclear messages go to the Review tab instead of your totals. '
          'Messages already added are skipped, so you can run this again.',
        ),
        const SizedBox(height: 20),
        Text('How far back?', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final r in InboxScanPage.ranges.keys)
              ChoiceChip(
                label: Text(r),
                selected: _range == r,
                onSelected: (_) => setState(() => _range = r),
              ),
          ],
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          key: const Key('startInboxScan'),
          onPressed: _start,
          icon: const Icon(Icons.play_arrow),
          label: Text('Scan last $_range'),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('skipInboxScan'),
          onPressed: _leave,
          child: const Text('Not now (you can do this later in Settings)'),
        ),
      ],
    );
  }

  Widget _scanning(BuildContext context) {
    final frac = _total == 0 ? null : _done / _total;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _total == 0 ? 'Reading inbox…' : 'Checked $_done of $_total messages',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(value: frac, minHeight: 8),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: _cancel?.cancelled == true
              ? null
              : () => setState(() => _cancel?.cancelled = true),
          child: Text(_cancel?.cancelled == true ? 'Stopping…' : 'Cancel'),
        ),
      ],
    );
  }

  Widget _result(BuildContext context) {
    final s = _summary!;
    final theme = Theme.of(context);
    Widget row(String label, int n, IconData icon) => ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text('$n', style: theme.textTheme.titleMedium),
    );
    return ListView(
      children: [
        Text(
          s.cancelled ? 'Scan stopped' : 'Scan complete',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          s.cancelled
              ? 'Partial results are kept. You can run it again from Settings.'
              : 'Checked ${plural(s.scanned, 'message')}.',
        ),
        const SizedBox(height: 12),
        row('Transactions found', s.found, Icons.search),
        row('Added', s.added, Icons.check_circle_outline),
        row('Already added (skipped)', s.duplicates, Icons.copy_all_outlined),
        row('Needs review', s.review, Icons.rule),
        row('Not transactions', s.skipped, Icons.block),
        const SizedBox(height: 20),
        if (s.review > 0)
          FilledButton.tonal(
            onPressed: () => _leave(openReview: true),
            child: Text('Review ${plural(s.review, 'message')}'),
          ),
        const SizedBox(height: 8),
        FilledButton(onPressed: _leave, child: const Text('Done')),
      ],
    );
  }

  Widget _failed(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Icon(Icons.error_outline, size: 48),
      const SizedBox(height: 12),
      Text('The scan could not finish.\n$_error', textAlign: TextAlign.center),
      const SizedBox(height: 20),
      FilledButton(onPressed: _start, child: const Text('Try again')),
      TextButton(onPressed: _leave, child: const Text('Not now')),
    ],
  );
}
