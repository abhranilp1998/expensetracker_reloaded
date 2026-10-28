import 'package:flutter/material.dart';

import 'package:expensetracker_reloaded/utils/money.dart';

/// Result of the manual-entry sheet.
class ManualEntry {
  const ManualEntry({required this.amountMinor, required this.type, this.note});

  /// Exact amount in minor units (paise). Use this for storage.
  final int amountMinor;

  /// Major units, for display/legacy callers only.
  double get amount => amountMinor / 100;
  final String type; // 'debit' | 'credit'
  final String? note;
}

/// Bottom sheet for entering a transaction by hand.
/// Pass [initial] to edit an existing transaction (title becomes "Edit").
Future<ManualEntry?> showAddTransactionSheet(
  BuildContext context, {
  ManualEntry? initial,
}) {
  return showModalBottomSheet<ManualEntry>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AddTransactionSheet(initial: initial),
  );
}

class _AddTransactionSheet extends StatefulWidget {
  const _AddTransactionSheet({this.initial});
  final ManualEntry? initial;

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _type = 'debit';
  String? _error;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _amount.text = (i.amountMinor / 100).toStringAsFixed(2);
      _note.text = i.note ?? '';
      _type = i.type;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    // Close the keyboard first so the tap is never swallowed by focus changes.
    FocusManager.instance.primaryFocus?.unfocus();
    final parsed = parseMoneyInput(_amount.text);
    if (!parsed.isValid) {
      setState(() => _error = parsed.error);
      return;
    }
    final note = _note.text.trim();
    Navigator.of(context).pop(
      ManualEntry(
        amountMinor: parsed.minor!,
        type: _type,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _editing ? 'Edit transaction' : 'Add transaction',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'debit', label: Text('Expense')),
                ButtonSegment(value: 'credit', label: Text('Income')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('amountField'),
              controller: _amount,
              autofocus: !_editing,
              inputFormatters: [MoneyInputFormatter()],
              // Clear a stale error as soon as the user edits the amount.
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Amount (${Money.symbol.trim()})',
                errorText: _error,
              ),
            ),
            TextField(
              controller: _note,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('saveTxn'),
              onPressed: _submit,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
