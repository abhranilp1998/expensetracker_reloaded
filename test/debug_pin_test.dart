import 'package:expensetracker_reloaded/routes/animation_preferences.dart';
import 'package:expensetracker_reloaded/routes/animation_variants.dart';
import 'package:expensetracker_reloaded/services/debug_unlock_service.dart';
import 'package:expensetracker_reloaded/widgets/debug_pin_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DateTime clock;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DebugUnlockService.lock();
    clock = DateTime(2026, 10, 29, 12);
    DebugUnlockService.now = () => clock;
  });

  group('PIN validation (#14)', () {
    test('accepts 4-6 digits only', () {
      expect(DebugUnlockService.validatePin('1234'), isNull);
      expect(DebugUnlockService.validatePin('123456'), isNull);
      expect(DebugUnlockService.validatePin(''), 'Enter a PIN');
      expect(DebugUnlockService.validatePin('abcd'), 'Digits only');
      expect(DebugUnlockService.validatePin('12a4'), 'Digits only');
      expect(DebugUnlockService.validatePin('123'), 'PIN must be 4-6 digits');
      expect(
        DebugUnlockService.validatePin('1234567'),
        'PIN must be 4-6 digits',
      );
      expect(() => DebugUnlockService.setPin('abcd'), throwsArgumentError);
    });
  });

  group('PIN storage', () {
    test('stored salted+hashed, never plain; salt differs per set', () async {
      await DebugUnlockService.setPin('2580');
      final p = await SharedPreferences.getInstance();
      final hash1 = p.getString('debugPinHashV1')!;
      final salt1 = p.getString('debugPinSaltV1')!;
      expect(p.getKeys().map(p.get).contains('2580'), isFalse);
      expect(hash1, DebugUnlockService.hashPin('2580', salt1));
      expect(hash1.length, 64);
      await DebugUnlockService.setPin('2580');
      expect(p.getString('debugPinSaltV1'), isNot(salt1));
      expect(p.getString('debugPinHashV1'), isNot(hash1));
      expect(await DebugUnlockService.verifyPin('2580'), isTrue);
    });

    test('remove clears pin and session', () async {
      await DebugUnlockService.setPin('2580');
      await DebugUnlockService.unlockWithPin('2580');
      await DebugUnlockService.removePin();
      expect(await DebugUnlockService.hasPin(), isFalse);
      expect(DebugUnlockService.sessionUnlocked, isFalse);
    });
  });

  group('lockout', () {
    Future<void> fail(int n) async {
      for (var i = 0; i < n; i++) {
        await DebugUnlockService.attemptPin('0000');
      }
    }

    test('5 wrong tries lock for 30s, then 2m, then 5m (capped)', () async {
      await DebugUnlockService.setPin('2580');
      await fail(4);
      expect(await DebugUnlockService.attemptsLeft(), 1);
      expect(await DebugUnlockService.attemptPin('0000'), PinResult.lockedOut);
      expect(
        await DebugUnlockService.lockRemaining(),
        const Duration(seconds: 30),
      );
      // Even the right PIN is refused while locked.
      expect(await DebugUnlockService.attemptPin('2580'), PinResult.lockedOut);

      clock = clock.add(const Duration(seconds: 30));
      expect(await DebugUnlockService.lockRemaining(), Duration.zero);
      await fail(5);
      expect(
        await DebugUnlockService.lockRemaining(),
        const Duration(minutes: 2),
      );

      clock = clock.add(const Duration(minutes: 2));
      await fail(5);
      expect(
        await DebugUnlockService.lockRemaining(),
        const Duration(minutes: 5),
      );

      clock = clock.add(const Duration(minutes: 5));
      await fail(5);
      expect(
        await DebugUnlockService.lockRemaining(),
        const Duration(minutes: 5),
      );
    });

    test(
      'lockout survives restart (persisted) and success resets it',
      () async {
        await DebugUnlockService.setPin('2580');
        await fail(5);
        // "Restart": fresh prefs instance reading the same stored values.
        final stored = (await SharedPreferences.getInstance());
        final values = {for (final k in stored.getKeys()) k: stored.get(k)!};
        SharedPreferences.setMockInitialValues(values.cast<String, Object>());
        expect(
          await DebugUnlockService.lockRemaining(),
          const Duration(seconds: 30),
        );

        clock = clock.add(const Duration(seconds: 31));
        await fail(2);
        expect(await DebugUnlockService.attemptPin('2580'), PinResult.ok);
        expect(await DebugUnlockService.attemptsLeft(), 5);
        // Level reset too: next lockout is 30s again.
        await fail(5);
        expect(
          await DebugUnlockService.lockRemaining(),
          const Duration(seconds: 30),
        );
      },
    );
  });

  group('PIN dialog', () {
    Future<void> open(WidgetTester t, PinDialogMode mode) async {
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) => TextButton(
              onPressed: () => showDebugPinDialog(c, mode),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await t.tap(find.text('go'));
      await t.pumpAndSettle();
    }

    testWidgets('setup filters letters and requires matching confirm', (
      t,
    ) async {
      await open(t, PinDialogMode.setup);
      await t.enterText(find.byKey(const Key('pinField')), 'ab12cd34');
      final field = t.widget<TextField>(find.byKey(const Key('pinField')));
      expect(field.controller!.text, '1234');
      await t.enterText(find.byKey(const Key('pinConfirm')), '1235');
      await t.tap(find.text('Set PIN'));
      await t.pump();
      expect(find.text('PINs do not match'), findsOneWidget);
      expect(await DebugUnlockService.hasPin(), isFalse);
      await t.enterText(find.byKey(const Key('pinConfirm')), '1234');
      await t.tap(find.text('Set PIN'));
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(await DebugUnlockService.verifyPin('1234'), isTrue);
    });

    testWidgets('tapping outside does not close the dialog', (t) async {
      await open(t, PinDialogMode.setup);
      await t.tapAt(const Offset(5, 5));
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  test('showcase labels are human, descriptions match animations (#9 #10)', () {
    for (final type in AnimationType.values) {
      final label = AnimationVariants.getAnimationName(type);
      expect(label, isNot(type.name));
      expect(label, isNotEmpty);
    }
    expect(
      AnimationVariants.getAnimationName(AnimationType.fadeSlide),
      'Fade + Slide',
    );
    final d = AnimationPreferencesService.getDescription;
    expect(d(AnimationType.bouncy), contains('left'));
    expect(d(AnimationType.liquid), contains('right'));
    expect(d(AnimationType.morphing), contains('below'));
    expect(d(AnimationType.kaleidoscope), contains('growing'));
    expect(d(AnimationType.elasticBounce), contains('top right'));
  });
}
