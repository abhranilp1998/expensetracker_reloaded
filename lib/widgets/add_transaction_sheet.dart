import 'package:flutter/material.dart';

/// Result of the manual-entry sheet.
class ManualEntry {
  const ManualEntry({required this.amount, required this.type, this.note});
  final double amount;
  final String type; // 'debit' | 'credit'
  final String? note;
}

/// Bottom sheet for entering a transaction by hand.
Future<ManualEntry?> showAddTransactionSheet(BuildContext context) {
  return showModalBottomSheet<ManualEntry>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _AddTransactionSheet(),
  );
}

class _AddTransactionSheet extends StatefulWidget {
  const _AddTransactionSheet();

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _type = 'debit';
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    // Close the keyboard first so the tap is never swallowed by focus changes.
    FocusManager.instance.primaryFocus?.unfocus();
    final value = double.tryParse(_amount.text.replaceAll(',', '').trim());
    if (value == null || value <= 0) {
      setState(() => _error = 'Enter an amount greater than 0');
      return;
    }
    final note = _note.text.trim();
    Navigator.of(context).pop(
      ManualEntry(amount: value, type: _type, note: note.isEmpty ? null : note),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add transaction',
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
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Amount (₹)',
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
