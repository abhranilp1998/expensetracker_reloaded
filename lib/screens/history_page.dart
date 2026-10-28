import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:expensetracker_reloaded/data/txn_view.dart';
import 'package:expensetracker_reloaded/domain/summary/summary.dart';
import 'package:expensetracker_reloaded/providers/providers.dart';
import 'package:expensetracker_reloaded/widgets/app_drawer.dart';
import 'package:expensetracker_reloaded/widgets/transaction_tile.dart';

enum _ActivityFilter { day, week, month, all }

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key, this.asTab = false});

  /// When true, shows a drawer (tab inside MainShell).
  final bool asTab;

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  _ActivityFilter _filter = _ActivityFilter.all;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filtered(
    List<Map<String, dynamic>> all,
    DateTime now,
  ) {
    Iterable<Map<String, dynamic>> rows = all;
    switch (_filter) {
      case _ActivityFilter.day:
        final r = DateRange.day(now);
        rows = rows.where((t) {
          final d = DateTime.parse(t['time'].toString());
          return !d.isBefore(r.start) && d.isBefore(r.end);
        });
      case _ActivityFilter.week:
        final r = DateRange.week(now);
        rows = rows.where((t) {
          final d = DateTime.parse(t['time'].toString());
          return !d.isBefore(r.start) && d.isBefore(r.end);
        });
      case _ActivityFilter.month:
        final r = DateRange.month(now);
        rows = rows.where((t) {
          final d = DateTime.parse(t['time'].toString());
          return !d.isBefore(r.start) && d.isBefore(r.end);
        });
      case _ActivityFilter.all:
        break;
    }
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      rows = rows.where((t) => txnMatchesSearch(t, q));
    }
    return rows.toList();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(allTransactionsProvider);
    final now = ref.watch(clockProvider)();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Activity', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: widget.asTab || ModalRoute.of(context)?.canPop != true
          ? const AppDrawer()
          : null,
      body: Column(
        children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                key: const ValueKey('activity-search'),
                controller: _search,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search merchant, note, amount…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(_search.clear),
                        ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final f in _ActivityFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(switch (f) {
                        _ActivityFilter.day => 'Day',
                        _ActivityFilter.week => 'Week',
                        _ActivityFilter.month => 'Month',
                        _ActivityFilter.all => 'All',
                      }),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: all.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (rows) {
                final maps = _filtered(txnMaps(rows), now);
                if (maps.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 72, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }
                final grouped = _groupByDate(maps);
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final date = grouped.keys.elementAt(index);
                    final dayTx = grouped[date]!;
                    final total = dayTx.fold<double>(
                      0.0,
                      (sum, t) => t['type'] == 'credit'
                          ? sum
                          : sum + (t['amount'] as num).toDouble(),
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatHeader(date),
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
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...dayTx.asMap().entries.map(
                              (e) => TransactionTile(
                                transaction: e.value,
                                index: e.key,
                                compact: true,
                              ),
                            ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(
      List<Map<String, dynamic>> transactions) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final t in transactions.reversed) {
      final date = DateTime.parse(t['time'].toString());
      final key = DateFormat('yyyy-MM-dd').format(date);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    return grouped;
  }

  String _formatHeader(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(date);
  }
}
