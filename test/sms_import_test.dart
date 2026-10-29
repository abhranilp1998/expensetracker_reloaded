import 'package:drift/native.dart';
import 'package:expensetracker_reloaded/data/db/app_database.dart';
import 'package:expensetracker_reloaded/data/repositories/transaction_repository.dart';
import 'package:expensetracker_reloaded/domain/sms/sms_classifier.dart';
import 'package:expensetracker_reloaded/screens/inbox_scan_page.dart';
import 'package:expensetracker_reloaded/services/sms_import.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final at = DateTime(2026, 10, 20, 10, 30);
  const debit =
      'Rs.450.00 debited from A/c XX1234 on 20-10-26 to VPA zomato@upi. UPI Ref 612345678901';
  const promo =
      'Rs. 3120 Super Duolingo perk with your Airtel plan. Claim on Airtel Thanks app';
  const unsure = 'Your Netflix plan of Rs 649 will be charged';

  group('promo filter (bug #15)', () {
    test('Airtel Duolingo promo is dropped, not reviewed', () {
      final c = const SmsClassifier().classify(
        body: 'Rs. 3120 Super Duolingo perk',
        sender: 'VM-AIRTEL',
        receivedAt: at,
      );
      expect(c.decision, Decision.drop);
      final c2 = const SmsClassifier().classify(
        body: promo,
        sender: 'VM-AIRTEL',
        receivedAt: at,
      );
      expect(c2.decision, Decision.drop);
    });
    test('real debit still accepted', () {
      final c = const SmsClassifier().classify(
        body: debit,
        sender: 'VM-HDFCBK',
        receivedAt: at,
      );
      expect(c.decision, Decision.accept);
    });
  });

  group('importMessages (bug #12)', () {
    late AppDatabase db;
    late TransactionRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = TransactionRepository(db);
    });
    tearDown(() => db.close());

    final inbox = [
      InboxMessage(address: 'VM-HDFCBK', body: debit, date: at),
      InboxMessage(address: 'VM-AIRTEL', body: promo, date: at),
      InboxMessage(address: 'VM-NFLX', body: unsure, date: at),
      InboxMessage(address: 'AX-OTP', body: 'Your OTP is 1234', date: at),
    ];

    test('summary counts and re-scan adds nothing twice', () async {
      final progress = <int>[];
      final s1 = await importMessages(
        repo,
        inbox,
        onProgress: (d, t) => progress.add(d),
      );
      expect(progress, [1, 2, 3, 4]);
      expect(s1.scanned, 4);
      expect(s1.added + s1.review, greaterThanOrEqualTo(1));
      expect(s1.added, 1);
      expect(s1.duplicates, 0);
      final s2 = await importMessages(repo, inbox);
      expect(s2.added, 0);
      expect(s2.review, 0);
      expect(s2.duplicates, s1.added + s1.review);
      expect(await repo.count(includeDeleted: true), s1.added + s1.review);
    });

    test(
      'same SMS (sender+time+body) is a duplicate even if hash differs',
      () async {
        final ok = await repo.insert(
          NewTxn(
            amountMinor: 45000,
            type: 'debit',
            source: 'sms',
            occurredAt: at,
            dedupeHash: 'legacy-hash',
            rawBody: debit,
            sender: 'VM-HDFCBK',
          ),
        );
        expect(ok, isTrue);
        final s = await importMessages(repo, inbox.take(1).toList());
        expect(s.duplicates, 1);
        expect(s.added, 0);
      },
    );

    test('cancel stops early and reports cancelled', () async {
      final token = ImportCancelToken();
      final s = await importMessages(
        repo,
        inbox,
        cancel: token,
        onProgress: (d, _) {
          if (d == 1) token.cancelled = true;
        },
      );
      expect(s.cancelled, isTrue);
      expect(s.scanned, 1);
    });
  });

  testWidgets('scan page: nothing read until Start; shows summary', (t) async {
    Duration? asked;
    await t.pumpWidget(
      MaterialApp(
        home: InboxScanPage(
          scanner: (w, {onProgress, cancel}) async {
            asked = w;
            onProgress?.call(1, 2);
            onProgress?.call(2, 2);
            return ImportSummary()
              ..scanned = 2
              ..added = 1
              ..review = 1;
          },
        ),
      ),
    );
    expect(find.text('Find past transactions'), findsOneWidget);
    expect(asked, isNull);
    await t.tap(find.text('30 days'));
    await t.pump();
    await t.tap(find.byKey(const Key('startInboxScan')));
    await t.pumpAndSettle();
    expect(asked, const Duration(days: 30));
    expect(find.text('Scan complete'), findsOneWidget);
    expect(find.text('Review 1 message'), findsOneWidget);
  });
}
