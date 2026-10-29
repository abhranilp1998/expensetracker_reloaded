import 'package:drift/native.dart';
import 'package:expensetracker_reloaded/data/db/app_database.dart';
import 'package:expensetracker_reloaded/data/repositories/transaction_repository.dart';
import 'package:expensetracker_reloaded/domain/summary/summary.dart';
import 'package:expensetracker_reloaded/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DateRange day/week/month (local calendar)', () {
    final now = DateTime(2026, 10, 28, 15); // Wednesday
    expect(DateRange.day(now).start, DateTime(2026, 10, 28));
    expect(DateRange.day(now).end, DateTime(2026, 10, 29));
    expect(DateRange.week(now).start, DateTime(2026, 10, 26));
    expect(DateRange.month(now).start, DateTime(2026, 10, 1));
    expect(DateRange.month(DateTime(2026, 12, 5)).end, DateTime(2027, 1, 1));
  });

  group('today summary with fake clock', () {
    late AppDatabase db;
    late ProviderContainer c;
    final now = DateTime(2026, 10, 12, 10);

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      c = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => now),
          databaseProvider.overrideWithValue(db),
        ],
      );
      final repo = c.read(transactionRepositoryProvider);
      Future<void> add(String h, int amt, String type, DateTime at) =>
          repo.insert(
            NewTxn(
              amountMinor: amt,
              type: type,
              source: 'manual',
              occurredAt: at,
              dedupeHash: h,
            ),
          );
      await add(
        'y',
        10000,
        'debit',
        DateTime(2026, 10, 11, 23, 59),
      ); // yesterday
      await add('a', 25000, 'debit', DateTime(2026, 10, 12, 0, 1));
      await add('b', 5000, 'debit', DateTime(2026, 10, 12, 9));
      await add('c', 100000, 'credit', DateTime(2026, 10, 12, 9, 30));
      await add('d', 7000, 'debit', DateTime(2026, 10, 12, 9, 45));
      final rows = await repo.getRange(
        DateTime(2026, 10, 12),
        DateTime(2026, 10, 13),
      );
      await repo.softDelete(rows.firstWhere((r) => r.dedupeHash == 'd').id);
    });
    tearDown(() async {
      c.dispose();
      await db.close();
    });

    test(
      '23:59 is yesterday, 00:01 is today; net = income - spent; deleted excluded',
      () async {
        final sub = c.listen(todaySummaryProvider, (_, _) {});
        await c.read(
          rangeTransactionsProvider(c.read(todayRangeProvider)).future,
        );
        final s = sub.read();
        expect(s.spentMinor, 30000);
        expect(s.incomeMinor, 100000);
        expect(s.netMinor, 70000);
        expect(s.count, 3);
        sub.close();
      },
    );

    test('month includes yesterday', () async {
      final sub = c.listen(monthSummaryProvider, (_, _) {});
      await c.read(
        rangeTransactionsProvider(c.read(monthRangeProvider)).future,
      );
      expect(sub.read().spentMinor, 40000);
      sub.close();
    });
  });
}
