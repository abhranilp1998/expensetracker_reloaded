import 'package:drift/native.dart';
import 'package:expensetracker_reloaded/data/db/app_database.dart';
import 'package:expensetracker_reloaded/data/repositories/transaction_repository.dart';
import 'package:expensetracker_reloaded/data/txn_view.dart';
import 'package:expensetracker_reloaded/widgets/add_transaction_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('repository manual entry', () {
    late AppDatabase db;
    late TransactionRepository repo;
    final now = DateTime(2026, 10, 26, 12);

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = TransactionRepository(db, clock: () => now);
    });
    tearDown(() => db.close());

    test(
      'addManual stores paise and type; two identical entries both kept',
      () async {
        await repo.addManual(amount: 12.34, note: 'tea');
        await repo.addManual(amount: 12.34, note: 'tea');
        await repo.addManual(amount: 500, type: 'credit');
        final all = await repo.getRange(DateTime(2026), DateTime(2027));
        expect(all, hasLength(3));
        expect(all.where((r) => r.amountMinor == 1234), hasLength(2));
        expect(all.where((r) => r.type == 'credit').single.source, 'manual');
        final m = txnToMap(all.firstWhere((r) => r.note == 'tea'));
        expect(m['amount'], 12.34);
        expect(m['message'], 'tea');
      },
    );

    test('softDeleteAll hides everything', () async {
      await repo.addManual(amount: 10);
      await repo.addManual(amount: 20);
      await repo.softDeleteAll();
      expect(await repo.getRange(DateTime(2026), DateTime(2027)), isEmpty);
    });
  });

  testWidgets('add sheet validates and returns entry', (tester) async {
    ManualEntry? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => TextButton(
            onPressed: () async => result = await showAddTransactionSheet(ctx),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Enter an amount'), findsOneWidget);
    await tester.tap(find.text('Income'));
    await tester.enterText(find.byKey(const Key('amountField')), '1,250.5');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result?.amount, 1250.5);
    expect(result?.type, 'credit');
  });
}
