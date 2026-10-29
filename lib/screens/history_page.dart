import 'package:expensetracker_reloaded/data/txn_view.dart';
import 'package:expensetracker_reloaded/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expensetracker_reloaded/widgets/history_transaction_tile.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allTransactionsProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: const Text(
          'Transaction History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: null,
        initialData: all.hasValue ? txnMaps(all.value!) : null,
        builder: (context, snapshot) {
          if (all.isLoading && !all.hasValue) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.green.shade600,
              ),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No transaction history yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your expenses will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          final transactions = snapshot.data!;
          final groupedTransactions = _groupTransactionsByDate(transactions);
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedTransactions.length,
            itemBuilder: (context, index) {
              final date = groupedTransactions.keys.elementAt(index);
              final dayTransactions = groupedTransactions[date]!;
              final total = dayTransactions.fold<double>(
                0.0,
                (sum, t) => t['type'] == 'credit' ? sum : sum + (t['amount'] as num).toDouble(),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDateHeader(date),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...dayTransactions.map((t) => HistoryTransactionTile(
                        transaction: t,
                      )),
                  const SizedBox(height: 8),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupTransactionsByDate(
      List<Map<String, dynamic>> transactions) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    
    for (final t in transactions.reversed) {
      final date = DateTime.parse(t['time'].toString());
      final key = DateFormat('yyyy-MM-dd').format(date);
      
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(t);
    }
    
    return grouped;
  }

  String _formatDateHeader(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }
}
