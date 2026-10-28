import 'package:drift/native.dart';
import 'package:expensetracker_reloaded/data/db/app_database.dart';
import 'package:expensetracker_reloaded/data/repositories/transaction_repository.dart';
import 'package:expensetracker_reloaded/data/txn_view.dart';
import 'package:expensetracker_reloaded/providers/providers.dart';
import 'package:expensetracker_reloaded/screens/profile_page.dart';
import 'package:expensetracker_reloaded/services/debug_unlock_service.dart';
import 'package:expensetracker_reloaded/utils/money.dart';
import 'package:expensetracker_reloaded/widgets/debug_pin_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fixes from the run4 device smoke check.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'userName': 'Abhranil'}));

  test('plural helper: 1 try / 2 tries', () {
    expect(plural(1, 'try', 'tries'), '1 try');
    expect(plural(4, 'try', 'tries'), '4 tries');
  });

  test('txnTimeLabel prefixes older days', () {
    final now = DateTime(2026, 10, 29, 9);
    expect(
      txnTimeLabel(DateTime(2026, 10, 29, 8, 5), withDate: true, now: now),
      '08:05 AM',
    );
    expect(
      txnTimeLabel(DateTime(2026, 10, 28, 23, 26), withDate: true, now: now),
      'Yesterday, 11:26 PM',
    );
    expect(
      txnTimeLabel(DateTime(2026, 10, 20, 10, 0), withDate: true, now: now),
      '20 Oct, 10:00 AM',
    );
    expect(
      txnTimeLabel(DateTime(2025, 1, 2, 10, 0), withDate: true, now: now),
      '2 Jan 2025, 10:00 AM',
    );
    expect(txnTimeLabel(DateTime(2026, 10, 20, 10, 0), now: now), '10:00 AM');
  });

  test('Recent = newest 5 of any date, empty only when none', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = TransactionRepository(db);
    final c = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    c.listen(recentTransactionsProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(c.read(recentTransactionsProvider), isEmpty);

    final base = DateTime(2026, 10, 1);
    for (var i = 0; i < 7; i++) {
      await repo.addManual(
        amountMinor: 100 * (i + 1),
        note: 'n$i',
        at: base.add(Duration(days: i)),
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final recent = c.read(recentTransactionsProvider);
    expect(recent.length, 5);
    expect(recent.first.note, 'n6'); // newest first
    expect(recent.last.note, 'n2');
  });

  testWidgets('PIN dialog says "1 try left"', (t) async {
    DebugUnlockService.now = DateTime.now;
    await DebugUnlockService.setPin('2580');
    for (var i = 0; i < 3; i++) {
      await DebugUnlockService.attemptPin('0000');
    }
    await t.pumpWidget(
      const MaterialApp(home: DebugPinDialog(mode: PinDialogMode.unlock)),
    );
    await t.pump();
    await t.enterText(find.byKey(const Key('pinField')), '1111');
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
    expect(find.text('Wrong PIN. 1 try left.'), findsOneWidget);
  });

  testWidgets('Profile shows the currency note', (t) async {
    await t.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProfilePage())),
    );
    await t.pumpAndSettle();
    expect(find.text(currencySymbolNote), findsOneWidget);
  });
}
