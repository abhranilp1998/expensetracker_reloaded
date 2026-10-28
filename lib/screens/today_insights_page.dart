import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:expensetracker_reloaded/data/txn_view.dart';
import 'package:expensetracker_reloaded/domain/summary/insights.dart';
import 'package:expensetracker_reloaded/providers/providers.dart';
import 'package:expensetracker_reloaded/widgets/transaction_tile.dart';
import 'package:expensetracker_reloaded/utils/money.dart';

/// Hero destination for today's spend card — insights, not a bigger number.
class TodayInsightsPage extends ConsumerWidget {
  const TodayInsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = ref.watch(clockProvider)();
    final todayRows = ref.watch(todayTransactionsProvider).value ?? const [];
    final yRange = yesterdayRange(now);
    final yesterdayRows =
        ref.watch(rangeTransactionsProvider(yRange)).value ?? const [];
    final weekRows =
        ref
            .watch(rangeTransactionsProvider(ref.watch(weekRangeProvider)))
            .value ??
        const [];
    final insights = buildDayInsights(
      now: now,
      todayRows: todayRows,
      yesterdayRows: yesterdayRows,
      weekRows: weekRows,
    );
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Today\'s insights')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Hero(
            tag: 'today-total-card',
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primary.withValues(alpha: 0.65)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's spend",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: cs.onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Money.minor(insights.today.spentMinor),
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Income ${Money.minor(insights.today.incomeMinor)}  ·  '
                      'Net ${Money.minor(insights.today.netMinor, signed: true)}',
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _CompareRow(
            label: 'vs yesterday',
            other: insights.yesterday.spent,
            pct: insights.vsYesterdayPct,
          ),
          const SizedBox(height: 8),
          _CompareRow(
            label: 'vs 7-day average',
            other: insights.dailyAverageSpent,
            pct: insights.vsAveragePct,
          ),
          const SizedBox(height: 28),
          Text(
            'By category',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (insights.byCategory.isEmpty)
            Text('No debits yet today', style: theme.textTheme.bodyMedium)
          else
            ...insights.byCategory.entries.take(8).map((e) {
              final max = insights.byCategory.values.first;
              final frac = max <= 0 ? 0.0 : e.value / max;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(Money.major(e.value)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: frac.clamp(0.0, 1.0),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 28),
          Text(
            'By hour',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var h = 0; h < 24; h++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: FractionallySizedBox(
                        heightFactor: () {
                          final maxH = insights.byHour.values.fold<double>(
                            0,
                            (a, b) => a > b ? a : b,
                          );
                          if (maxH <= 0) return 0.05;
                          return (0.05 + 0.95 * (insights.byHour[h]! / maxH))
                              .clamp(0.05, 1.0);
                        }(),
                        alignment: Alignment.bottomCenter,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(
                              alpha: insights.byHour[h]! > 0 ? 0.85 : 0.15,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('12a', style: theme.textTheme.labelSmall),
              Text('12p', style: theme.textTheme.labelSmall),
              Text('11p', style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Top transactions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (insights.topDebits.isEmpty)
            Text('Nothing to show yet', style: theme.textTheme.bodyMedium)
          else
            ...insights.topDebits.asMap().entries.map(
              (e) =>
                  TransactionTile(transaction: txnToMap(e.value), index: e.key),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.label,
    required this.other,
    required this.pct,
  });
  final String label;
  final double other;
  final double pct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final up = pct > 0.5;
    final down = pct < -0.5;
    final color = up
        ? theme.colorScheme.error
        : down
        ? theme.colorScheme.tertiary
        : theme.colorScheme.onSurfaceVariant;
    final arrow = up
        ? '▲'
        : down
        ? '▼'
        : '●';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelLarge),
                Text(Money.major(other), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            '$arrow ${pct.abs().toStringAsFixed(0)}%',
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
