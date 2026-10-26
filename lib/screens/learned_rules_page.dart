import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// On-device rules learned from review decisions. Deleting one sends
/// future matching SMS back to the review queue.
class LearnedRulesPage extends ConsumerWidget {
  const LearnedRulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(learnedRulesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Learned rules')),
      body: rules.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Could not load rules')),
        data: (rows) => rows.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No rules yet. Decisions you make in "Needs review" appear here.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: rows.length,
                itemBuilder: (_, i) {
                  final r = rows[i];
                  final (icon, label) = switch (r.action) {
                    'debit' => (Icons.arrow_upward, 'Expense'),
                    'credit' => (Icons.arrow_downward, 'Income'),
                    _ => (Icons.block, 'Ignore'),
                  };
                  return ListTile(
                    leading: Icon(icon),
                    title: Text(
                      '${r.sender.isEmpty ? 'Unknown sender' : r.sender} → $label',
                    ),
                    subtitle: Text(
                      r.sample ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      tooltip: 'Delete rule',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => ref
                          .read(transactionRepositoryProvider)
                          .deleteRule(r.id),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
