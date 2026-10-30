import 'package:drift/native.dart';
import 'package:expensetracker_reloaded/data/db/app_database.dart';
import 'package:expensetracker_reloaded/data/repositories/transaction_repository.dart';
import 'package:expensetracker_reloaded/domain/sms/sms_parser.dart';
import 'package:expensetracker_reloaded/providers/providers.dart';
import 'package:expensetracker_reloaded/routes/animation_preferences.dart';
import 'package:expensetracker_reloaded/routes/animation_showcase.dart';
import 'package:expensetracker_reloaded/routes/animation_variants.dart';
import 'package:expensetracker_reloaded/screens/review_queue_page.dart';
import 'package:expensetracker_reloaded/screens/comprehensive_settings_page.dart';
import 'package:expensetracker_reloaded/screens/today_insights_page.dart';
import 'package:expensetracker_reloaded/services/debug_unlock_service.dart';
import 'package:expensetracker_reloaded/services/theme_service.dart';
import 'package:expensetracker_reloaded/services/sms_import.dart';
import 'package:expensetracker_reloaded/services/sms_ingest.dart';
import 'package:expensetracker_reloaded/utils/money.dart';
import 'package:expensetracker_reloaded/widgets/debug_pin_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

TxnRow txn(String id, DateTime at, int minor, {String status = 'confirmed'}) =>
    TxnRow(
      id: id,
      amountMinor: minor,
      type: 'debit',
      source: 'sms',
      occurredAt: at.millisecondsSinceEpoch,
      dedupeHash: id,
      createdAt: at.millisecondsSinceEpoch,
      updatedAt: at.millisecondsSinceEpoch,
      deleted: false,
      syncStatus: 'pending',
      schemaVersion: 1,
      status: status,
      sender: 'VM-HDFCBK',
      rawBody: 'Rs.120.50 payment information',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Money.code = 'INR';
    DebugUnlockService.lock();
  });

  test('A1 very long manual amount returns validation instead of throwing', () {
    expect(() => parseMoneyInput(List.filled(40, '9').join()), returnsNormally);
    expect(
      parseMoneyInput(List.filled(40, '9').join()).error,
      'Amount is too large',
    );
    expect(parseMoneyInput('0000000000012.50').minor, 1250);
  });

  test(
    'A2 ordinary UPI wording must not deduplicate different payments',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = TransactionRepository(db);
      final at = DateTime(2026, 10, 28, 10);
      const first = 'Rs.500 debited from A/c XX1234 for UPI payment to CAFE';
      const second = 'Rs.500 debited from A/c XX1234 for UPI payment to SHOP';
      final extracted = const SmsParser().extract(first);
      // Synthetic input only: record what the parser interpreted as a bank reference.
      expect(extracted.reference, isNull);
      await ingestSms(repo, body: first, sender: 'VM-HDFCBK', receivedAt: at);
      await ingestSms(
        repo,
        body: second,
        sender: 'VM-HDFCBK',
        receivedAt: at.add(const Duration(days: 1)),
      );
      expect(await repo.count(), 2);
    },
  );

  test(
    'A3 a malformed SMS must not stop importing later valid messages',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = TransactionRepository(db);
      final at = DateTime(2026, 10, 28, 10);
      final summary = await importMessages(repo, [
        InboxMessage(
          address: 'VM-BROKEN',
          body: 'Rs.${List.filled(40, '9').join()} debited from A/c XX1234',
          date: at,
        ),
        InboxMessage(
          address: 'VM-HDFCBK',
          body: 'Rs.100 debited from A/c XX1234. UPI Ref 612345678901',
          date: at,
        ),
      ]);
      expect(summary.scanned, 2);
      expect(summary.added, 1);
      expect(summary.errors + summary.skipped, 1);
    },
  );

  testWidgets('A4 Review card fits a 360 logical pixel phone', (t) async {
    t.view.physicalSize = const Size(360, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final row = txn(
      'review',
      DateTime(2026, 10, 28, 23, 30),
      12050,
      status: 'review',
    );
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          reviewQueueProvider.overrideWith((ref) => Stream.value([row])),
        ],
        child: const MaterialApp(home: ReviewQueuePage()),
      ),
    );
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets('A5 old alphanumeric PIN can still be entered after upgrade', (
    t,
  ) async {
    const legacyPin = 'ab12';
    const legacySalt = '1730000000000000';
    SharedPreferences.setMockInitialValues({
      'debugPinSaltV1': legacySalt,
      'debugPinHashV1': DebugUnlockService.hashPin(legacyPin, legacySalt),
    });
    expect(await DebugUnlockService.hasPin(), isTrue);
    expect(await DebugUnlockService.verifyPin(legacyPin), isTrue);
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DebugPinDialog(mode: PinDialogMode.verifyCurrent)),
      ),
    );
    await t.enterText(find.byKey(const Key('pinField')), legacyPin);
    final field = t.widget<TextField>(find.byKey(const Key('pinField')));
    expect(field.controller!.text, legacyPin);
    expect(await DebugUnlockService.isLegacyPin(), isTrue);
    expect(await DebugUnlockService.attemptPin(legacyPin), PinResult.ok);
    expect(await DebugUnlockService.isLegacyPin(), isTrue);
    await DebugUnlockService.setPin('1234');
    expect(await DebugUnlockService.isLegacyPin(), isFalse);
    expect(DebugUnlockService.validatePin('ab12'), isNotNull);
  });
  testWidgets('A6 7-day average uses seven complete days before today', (
    t,
  ) async {
    final now = DateTime(2026, 10, 26, 12); // Monday
    final rows = [
      txn('today', now, 140000),
      for (var d = 1; d <= 7; d++)
        txn('prior-$d', now.subtract(Duration(days: d)), 10000),
    ];
    t.view.physicalSize = const Size(800, 1200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(() => now),
          rangeTransactionsProvider.overrideWith(
            (ref, range) => Stream.value(
              rows
                  .where(
                    (r) =>
                        r.occurredAt >= range.start.millisecondsSinceEpoch &&
                        r.occurredAt < range.end.millisecondsSinceEpoch,
                  )
                  .toList(),
            ),
          ),
        ],
        child: const MaterialApp(home: TodayInsightsPage()),
      ),
    );
    await t.pumpAndSettle();
    final label = find.text('vs avg of previous 7 days');
    final row = find.ancestor(of: label, matching: find.byType(Row)).first;
    // Previous complete days average 100; today's 1400 is 1300% above it.
    expect(
      find.descendant(of: row, matching: find.textContaining('1300')),
      findsOneWidget,
    );
  });

  testWidgets('A7 Showcase animation selection persists after reload', (
    t,
  ) async {
    AnimationVariants.setAnimationType(AnimationType.fadeSlide);
    await t.pumpWidget(const MaterialApp(home: AnimationPreview()));
    await t.pumpAndSettle();
    final tiles = find.byType(ExpansionTile);
    expect(tiles, findsNWidgets(AnimationType.values.length));
    await t.ensureVisible(tiles.at(1));
    await t.tap(tiles.at(1));
    await t.pumpAndSettle();
    final tile = find.byWidgetPredicate(
      (w) => w is AnimationTile && w.type == AnimationType.slideLeft,
    );
    t.widget<AnimationTile>(tile).onSelect();
    await t.pumpAndSettle();
    final selected = AnimationVariants.currentType;
    expect(selected, isNot(AnimationType.fadeSlide));
    AnimationVariants.setAnimationType(AnimationType.fadeSlide);
    expect(await AnimationPreferencesService.loadAnimationType(), selected);
  });

  testWidgets('A8 reset updates the selected theme shown in Settings', (
    t,
  ) async {
    const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => 1);
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    SharedPreferences.setMockInitialValues({
      'app_theme_mode': 'dark',
      'app_accent_color': 'blue',
      'animationType': AnimationType.slideLeft.toString(),
    });
    await ThemeService.initialize();
    AnimationVariants.setAnimationType(AnimationType.slideLeft);
    t.view.physicalSize = const Size(800, 1200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ComprehensiveSettingsPage()),
      ),
    );
    await t.pumpAndSettle();
    await t.ensureVisible(
      find.widgetWithText(OutlinedButton, 'Reset to Defaults'),
    );
    await t.tap(find.widgetWithText(OutlinedButton, 'Reset to Defaults'));
    await t.pumpAndSettle();
    await t.tap(find.text('Reset'));
    await t.pumpAndSettle();
    expect(container.read(themeControllerProvider).mode, ThemeMode.system);
    final systemTile = find.byWidgetPredicate(
      (w) => w is RadioListTile<ThemeMode> && w.value == ThemeMode.system,
    );
    expect(
      t.widget<RadioListTile<ThemeMode>>(systemTile).groupValue,
      ThemeMode.system,
    );
  });
}
