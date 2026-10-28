import 'package:expensetracker_reloaded/data/db/app_database.dart';
import 'package:expensetracker_reloaded/domain/summary/insights.dart';
import 'package:flutter_test/flutter_test.dart';

TxnRow row({
  required int amountMinor,
  required String type,
  required DateTime at,
  String? merchant,
  String id = 'x',
}) {
  final ms = at.toUtc().millisecondsSinceEpoch;
  return TxnRow(
    id: id,
    amountMinor: amountMinor,
    type: type,
    source: 'manual',
    occurredAt: ms,
    dedupeHash: id,
    createdAt: ms,
    updatedAt: ms,
    deleted: false,
    syncStatus: 'pending',
    schemaVersion: 1,
    status: 'confirmed',
    merchant: merchant,
  );
}

void main() {
  test('buildDayInsights category, hour, comparisons', () {
    final now = DateTime(2026, 10, 27, 15, 30);
    final today = [
      row(
        amountMinor: 50000,
        type: 'debit',
        at: now,
        merchant: 'Swiggy',
        id: '1',
      ),
      row(
        amountMinor: 20000,
        type: 'debit',
        at: now.subtract(const Duration(hours: 3)),
        merchant: 'Uber',
        id: '2',
      ),
      row(
        amountMinor: 100000,
        type: 'credit',
        at: now,
        merchant: 'Salary',
        id: '3',
      ),
    ];
    final yesterday = [
      row(
        amountMinor: 30000,
        type: 'debit',
        at: now.subtract(const Duration(days: 1)),
        merchant: 'Cafe',
        id: '4',
      ),
    ];
    final insights = buildDayInsights(
      now: now,
      todayRows: today,
      yesterdayRows: yesterday,
      weekRows: [...today, ...yesterday],
    );
    expect(insights.today.spent, 700);
    expect(insights.today.income, 1000);
    expect(insights.yesterday.spent, 300);
    expect(insights.byCategory['Swiggy'], 500);
    expect(insights.byCategory['Uber'], 200);
    expect(insights.topDebits.first.merchant, 'Swiggy');
    expect(insights.byHour[15], 500);
    expect(insights.vsYesterdayPct, closeTo(133.33, 0.1));
  });

  test('categoryLabel falls back sensibly', () {
    final r = row(
      amountMinor: 100,
      type: 'debit',
      at: DateTime(2026, 1, 1),
      id: 'z',
    );
    expect(categoryLabel(r), 'Manual');
  });
}
