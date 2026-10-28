import '../../data/db/app_database.dart';
import 'summary.dart';

/// Insights derived from today's (and comparison) transactions.
class DayInsights {
  final Summary today;
  final Summary yesterday;
  final double
  dailyAverageSpent; // from last 7 complete days excl. today if possible
  final Map<String, double> byCategory; // spent rupees
  final Map<int, double> byHour; // 0-23 spent rupees
  final List<TxnRow> topDebits;

  const DayInsights({
    required this.today,
    required this.yesterday,
    required this.dailyAverageSpent,
    required this.byCategory,
    required this.byHour,
    required this.topDebits,
  });

  double get vsYesterdayPct {
    if (yesterday.spent <= 0) return today.spent > 0 ? 100 : 0;
    return ((today.spent - yesterday.spent) / yesterday.spent) * 100;
  }

  double get vsAveragePct {
    if (dailyAverageSpent <= 0) return today.spent > 0 ? 100 : 0;
    return ((today.spent - dailyAverageSpent) / dailyAverageSpent) * 100;
  }
}

String categoryLabel(TxnRow r) {
  final m = r.merchant?.trim();
  if (m != null && m.isNotEmpty) return m;
  final s = r.sender?.trim();
  if (s != null && s.isNotEmpty) return s;
  final n = r.note?.trim();
  if (n != null && n.isNotEmpty) {
    return n.length > 24 ? '${n.substring(0, 24)}…' : n;
  }
  return r.source == 'manual' ? 'Manual' : 'Other';
}

DayInsights buildDayInsights({
  required DateTime now,
  required List<TxnRow> todayRows,
  required List<TxnRow> yesterdayRows,
  required List<TxnRow> previous7DaysRows,
}) {
  final today = summarize(todayRows);
  final yesterday = summarize(yesterdayRows);

  // Daily average over the 7 complete days before today
  // (rows from [previous7DaysRange]).
  final dailyAvg = summarize(previous7DaysRows).spent / 7.0;

  final byCat = <String, double>{};
  final byHour = <int, double>{for (var h = 0; h < 24; h++) h: 0.0};
  final debits = <TxnRow>[];

  for (final r in todayRows) {
    if (r.deleted || r.type == 'credit') continue;
    debits.add(r);
    final amt = r.amountMinor / 100.0;
    final label = categoryLabel(r);
    byCat[label] = (byCat[label] ?? 0) + amt;
    final local = DateTime.fromMillisecondsSinceEpoch(
      r.occurredAt,
      isUtc: true,
    ).toLocal();
    byHour[local.hour] = (byHour[local.hour] ?? 0) + amt;
  }

  debits.sort((a, b) => b.amountMinor.compareTo(a.amountMinor));

  // Sort categories by amount desc.
  final sortedCat = Map.fromEntries(
    byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
  );

  return DayInsights(
    today: today,
    yesterday: yesterday,
    dailyAverageSpent: dailyAvg,
    byCategory: sortedCat,
    byHour: byHour,
    topDebits: debits.take(5).toList(),
  );
}

/// The 7 complete days before today (today excluded, so a half-finished
/// day never drags the average down). Used for "vs 7-day average".
DateRange previous7DaysRange(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return DateRange(DateTime(today.year, today.month, today.day - 7), today);
}

DateRange yesterdayRange(DateTime now) {
  final y = now.subtract(const Duration(days: 1));
  return DateRange.day(y);
}
