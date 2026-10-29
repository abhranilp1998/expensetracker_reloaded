import '../../data/db/app_database.dart';

/// Totals in paise. net = income - spent.
class Summary {
  final int spentMinor;
  final int incomeMinor;
  final int count;
  const Summary(this.spentMinor, this.incomeMinor, this.count);
  static const empty = Summary(0, 0, 0);

  int get netMinor => incomeMinor - spentMinor;
  double get spent => spentMinor / 100;
  double get income => incomeMinor / 100;
  double get net => netMinor / 100;
}

Summary summarize(Iterable<TxnRow> rows) {
  var spent = 0, income = 0, n = 0;
  for (final r in rows) {
    if (r.deleted) continue;
    n++;
    if (r.type == 'credit') {
      income += r.amountMinor;
    } else {
      spent += r.amountMinor;
    }
  }
  return Summary(spent, income, n);
}

/// Local-calendar ranges, [start, end).
class DateRange {
  final DateTime start;
  final DateTime end;
  const DateRange(this.start, this.end);

  static DateRange day(DateTime now) {
    final s = DateTime(now.year, now.month, now.day);
    return DateRange(s, DateTime(now.year, now.month, now.day + 1));
  }

  /// Monday-start week.
  static DateRange week(DateTime now) {
    final s = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    return DateRange(s, DateTime(s.year, s.month, s.day + 7));
  }

  static DateRange month(DateTime now) => DateRange(
    DateTime(now.year, now.month),
    DateTime(now.year, now.month + 1),
  );

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;
  @override
  int get hashCode => Object.hash(start, end);
}
