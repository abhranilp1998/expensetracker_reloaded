import 'package:drift/native.dart';
import 'package:expensetracker_reloaded/data/db/app_database.dart';
import 'package:expensetracker_reloaded/data/repositories/transaction_repository.dart';
import 'package:expensetracker_reloaded/data/txn_view.dart';
import 'package:expensetracker_reloaded/domain/summary/summary.dart';
import 'package:expensetracker_reloaded/utils/money.dart';
import 'package:expensetracker_reloaded/widgets/add_transaction_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => Money.code = 'INR');

  group('parseMoneyInput (bug #2)', () {
    test('accepts plain amounts', () {
      expect(parseMoneyInput('120').minor, 12000);
      expect(parseMoneyInput('120.5').minor, 12050);
      expect(parseMoneyInput('120.50').minor, 12050);
      expect(parseMoneyInput('1,250.5').minor, 125050);
      expect(parseMoneyInput('.5').minor, 50);
    });
    test('rejects exponent, sign, 3 decimals, zero, junk', () {
      for (final bad in [
        '1e3',
        '-5',
        '+5',
        '1.234',
        '0',
        '0.00',
        'abc',
        '1 2',
      ]) {
        expect(parseMoneyInput(bad).isValid, isFalse, reason: bad);
        expect(parseMoneyInput(bad).error, isNotNull);
      }
      expect(parseMoneyInput('').error, 'Enter an amount');
    });
  });

  group('Money formatting (bugs #3, #16)', () {
    test('two decimals, grouping, signed net keeps minus', () {
      expect(Money.minor(112050), '₹1,120.50');
      expect(Money.minor(-112050, signed: true), '-₹1,120.50');
      expect(Money.minor(500, signed: true), '+₹5.00');
      expect(Money.minor(-500), '-₹5.00');
      expect(Money.minor(0, signed: true), '₹0.00');
    });
    test('plural', () {
      expect(plural(1, 'transaction'), '1 transaction');
      expect(plural(2, 'transaction'), '2 transactions');
      expect(plural(0, 'transaction'), '0 transactions');
    });
    test('displayed total equals sum of displayed rows', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = TransactionRepository(db);
      for (final m in [12050, 100000, 33, 67]) {
        await repo.addManual(amountMinor: m);
      }
      final rows = await repo.getRange(DateTime(2000), DateTime(2100));
      expect(Money.minor(summarize(rows).spentMinor), '₹1,121.50');
      await db.close();
    });
  });

  group('edit/delete (bug #8)', () {
    late AppDatabase db;
    late TransactionRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = TransactionRepository(db, clock: () => DateTime(2026, 10, 28, 12));
    });
    tearDown(() => db.close());

    test('edit changes amount/type/note and totals; delete removes', () async {
      await repo.addManual(amountMinor: 12050, note: 'Tea');
      await repo.addManual(amountMinor: 100000);
      final range = DateRange.day(DateTime(2026, 10, 28));
      var rows = await repo.getRange(range.start, range.end);
      expect(summarize(rows).spentMinor, 112050);

      final tea = rows.firstWhere((r) => r.note == 'Tea');
      await repo.editTxn(tea.id, amountMinor: 2000, type: 'credit', note: null);
      rows = await repo.getRange(range.start, range.end);
      final edited = rows.firstWhere((r) => r.id == tea.id);
      expect(edited.note, isNull);
      expect(txnTitle(edited), 'Income');
      expect(summarize(rows).spentMinor, 100000);
      expect(summarize(rows).netMinor, 2000 - 100000);

      await repo.softDelete(edited.id);
      rows = await repo.getRange(range.start, range.end);
      expect(rows, hasLength(1));
      expect(summarize(rows).incomeMinor, 0);
    });

    test('blank debit gets a title (bug #17)', () async {
      await repo.addManual(amountMinor: 100);
      final r = (await repo.getRange(DateTime(2026), DateTime(2027))).single;
      expect(txnTitle(r), 'Expense');
    });
  });

  testWidgets('amount field blocks 1e3 and error clears on edit', (t) async {
    ManualEntry? result;
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => TextButton(
            onPressed: () async => result = await showAddTransactionSheet(ctx),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('Amount (₹)'), findsOneWidget);
    final field = find.byKey(const Key('amountField'));
    await t.enterText(field, '1e3');
    // The formatter rejects the whole edit, so the field stays empty.
    expect(t.widget<TextField>(field).controller!.text, '');
    await t.tap(find.text('Save'));
    await t.pump();
    expect(find.text('Enter an amount'), findsOneWidget);
    await t.enterText(field, '12');
    await t.pump();
    expect(find.text('Enter an amount'), findsNothing);
    await t.enterText(field, '12.345');
    expect(t.widget<TextField>(field).controller!.text, '12');
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(result?.amountMinor, 1200);
  });
}
