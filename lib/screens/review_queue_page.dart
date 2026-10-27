import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../providers/providers.dart';
import '../widgets/app_drawer.dart';

/// Uncertain SMS waiting for a decision. Each decision is learned as a rule.
class ReviewQueuePage extends ConsumerWidget {
  const ReviewQueuePage({super.key, this.asTab = false});

  final bool asTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(reviewQueueProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Needs review')),
      drawer: asTab ? const AppDrawer() : null,
      body: queue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Could not load the queue')),
        data: (rows) => rows.isEmpty
            ? const Center(child: Text('All caught up'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _ReviewCard(row: rows[i]),
              ),
      ),
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({required this.row});
  final TxnRow row;

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final n = await ref
        .read(transactionRepositoryProvider)
        .resolveReview(row.id, action);
    if (!context.mounted) return;
    final label = switch (action) {
      'debit' => 'Expense',
      'credit' => 'Income',
      _ => 'Ignored',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          n > 1
              ? '$label · applied to $n similar messages. Rule saved.'
              : '$label · rule saved for similar messages.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final when = DateFormat(
      'd MMM, h:mm a',
    ).format(DateTime.fromMillisecondsSinceEpoch(row.occurredAt));
    final pct = ((row.confidence ?? 0) * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '₹${(row.amountMinor / 100).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text(
                  '${row.sender ?? ''} · $when',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              row.rawBody ?? '',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Confidence $pct%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => _decide(context, ref, 'debit'),
                    child: const Text('Expense'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => _decide(context, ref, 'credit'),
                    child: const Text('Income'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _decide(context, ref, 'ignore'),
                    child: const Text('Ignore'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
