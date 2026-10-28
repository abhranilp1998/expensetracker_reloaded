import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:expensetracker_reloaded/providers/providers.dart';
import 'package:expensetracker_reloaded/utils/money.dart';
import 'package:expensetracker_reloaded/widgets/add_transaction_sheet.dart';

/// Edit / delete for one transaction row (bug #8).
/// [txn] is the map from `txnToMap` (needs 'id', 'amountMinor', 'type', 'note').
/// Totals on every screen update by themselves: they are derived from the
/// Drift watch streams, so nothing needs a manual refresh here.

/// Tap: open the edit sheet prefilled with the row.
Future<void> editTransaction(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> txn,
) async {
  final note = (txn['note'] as String?) ?? '';
  final entry = await showAddTransactionSheet(
    context,
    initial: ManualEntry(
      amountMinor: txn['amountMinor'] as int,
      type: txn['type'] as String,
      note: note.isEmpty ? null : note,
    ),
  );
  if (entry == null) return;
  await ref
      .read(transactionRepositoryProvider)
      .editTxn(
        txn['id'] as String,
        amountMinor: entry.amountMinor,
        type: entry.type,
        note: entry.note,
      );
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Transaction updated')));
  }
}

/// Asks first, then soft-deletes (row stays in DB with deleted=true).
Future<bool> confirmDeleteTransaction(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> txn,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete transaction?'),
      content: Text(
        '${Money.minor(txn['amountMinor'] as int)} · ${txn['message']}\n'
        'Totals will be recalculated.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('confirmDeleteTxn'),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  await ref.read(transactionRepositoryProvider).softDelete(txn['id'] as String);
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
  }
  return true;
}

/// Long-press: small sheet with Edit / Delete.
Future<void> showTransactionActions(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> txn,
) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit'),
            onTap: () => Navigator.pop(ctx, 'edit'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Delete'),
            onTap: () => Navigator.pop(ctx, 'delete'),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted) return;
  if (choice == 'edit') await editTransaction(context, ref, txn);
  if (choice == 'delete') await confirmDeleteTransaction(context, ref, txn);
}
