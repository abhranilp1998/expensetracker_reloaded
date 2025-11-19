import 'package:flutter/material.dart';
import 'package:expensetracker_reloaded/services/storage_service.dart';
import 'package:expensetracker_reloaded/services/theme_service.dart';
import 'package:intl/intl.dart';

/// Till Now page - shows all-time statistics and summaries
class TillNowPage extends StatefulWidget {
  const TillNowPage({super.key});

  @override
  State<TillNowPage> createState() => _TillNowPageState();
}

class _TillNowPageState extends State<TillNowPage> {
  late Future<List<Map<String, dynamic>>> _transactionsFuture;
  late Future<double> _totalSpentFuture;
  late Future<double> _weekTotalFuture;
  late Future<double> _monthTotalFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _transactionsFuture = StorageService.getTransactions();
    _totalSpentFuture = StorageService.calculateTotal(DateTime(2000)); // All time
    _weekTotalFuture = StorageService.calculateTotal(
      DateTime.now().subtract(const Duration(days: 7)),
    );
    _monthTotalFuture = StorageService.calculateTotal(
      DateTime.now().subtract(const Duration(days: 30)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.getScaffoldBg(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.getAppBarBg(),
        title: const Text(
          'Till Now',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary stats
            _buildSummaryCard(),
            const SizedBox(height: 24),

            // Total spent card
            Text(
              'Financial Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            FutureBuilder<double>(
              future: _totalSpentFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                return _buildBigStatCard(
                  'Total Spent (All Time)',
                  '₹${snapshot.data!.toStringAsFixed(2)}',
                  Colors.red,
                  Icons.trending_down,
                );
              },
            ),
            const SizedBox(height: 12),
            FutureBuilder<double>(
              future: _monthTotalFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                return _buildBigStatCard(
                  'This Month',
                  '₹${snapshot.data!.toStringAsFixed(2)}',
                  Colors.orange,
                  Icons.calendar_month,
                );
              },
            ),
            const SizedBox(height: 12),
            FutureBuilder<double>(
              future: _weekTotalFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                return _buildBigStatCard(
                  'This Week',
                  '₹${snapshot.data!.toStringAsFixed(2)}',
                  Colors.blue,
                  Icons.calendar_view_week,
                );
              },
            ),
            const SizedBox(height: 24),

            // Transactions analysis
            Text(
              'Transaction Analysis',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final transactions = snapshot.data!;
                if (transactions.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildAnalysisCards(transactions);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade200),
      ),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Complete Expense History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'View complete statistics and analysis of all your expenses from the beginning. Track spending patterns, identify trends, and manage your finances better.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green.shade800,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCards(List<Map<String, dynamic>> transactions) {
    // Calculate stats
    double averageTransaction = 0;
    double maxTransaction = 0;
    double minTransaction = double.infinity;
    int totalTransactions = transactions.length;

    for (final t in transactions) {
      final amount = (t['amount'] as num).toDouble();
      averageTransaction += amount;
      if (amount > maxTransaction) maxTransaction = amount;
      if (amount < minTransaction) minTransaction = amount;
    }

    averageTransaction = totalTransactions > 0 ? averageTransaction / totalTransactions : 0;
    if (minTransaction == double.infinity) minTransaction = 0;

    return Column(
      children: [
        _buildAnalysisItem(
          'Total Transactions',
          totalTransactions.toString(),
          Colors.purple,
          Icons.receipt,
        ),
        const SizedBox(height: 12),
        _buildAnalysisItem(
          'Average Transaction',
          '₹${averageTransaction.toStringAsFixed(2)}',
          Colors.blue,
          Icons.trending_up,
        ),
        const SizedBox(height: 12),
        _buildAnalysisItem(
          'Highest Transaction',
          '₹${maxTransaction.toStringAsFixed(2)}',
          Colors.red,
          Icons.trending_up,
        ),
        const SizedBox(height: 12),
        _buildAnalysisItem(
          'Lowest Transaction',
          '₹${minTransaction.toStringAsFixed(2)}',
          Colors.green,
          Icons.trending_down,
        ),
        const SizedBox(height: 24),
        _buildTransactionsList(transactions),
      ],
    );
  }

  Widget _buildAnalysisItem(String label, String value, Color color, IconData icon) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List<Map<String, dynamic>> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length > 10 ? 10 : transactions.length,
          itemBuilder: (context, index) {
            // Get from end (newest first)
            final transaction = transactions[transactions.length - 1 - index];
            final amount = transaction['amount'] as num;
            final dateTime = DateTime.parse(transaction['time'].toString());
            final message = transaction['message'] as String?;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message ?? 'Transaction',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            DateFormat('MMM d, yyyy HH:mm').format(dateTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '-₹${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (transactions.length > 10)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '+${transactions.length - 10} more transactions',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
