import 'package:drift/native.dart';
import 'package:expensetracker_reloaded/data/db/app_database.dart';
import 'package:expensetracker_reloaded/data/repositories/transaction_repository.dart';
import 'package:expensetracker_reloaded/domain/sms/sms_classifier.dart';
import 'package:expensetracker_reloaded/services/sms_ingest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TransactionRepository(db);
  });
  tearDown(() => db.close());

  final at = DateTime(2026, 10, 12, 9);
  final all = (DateTime(2000), DateTime(2100));
  const debit =
      'Rs.250 debited from a/c XX12 to swiggy@icici UPI Ref No 428500009999';
  const unsure = 'Rs 499 towards your Netflix subscription';

  test('live SMS + same SMS from inbox import = one row', () async {
    final live = await ingestSms(
      repo,
      body: debit,
      sender: 'VM-HDFCBK',
      receivedAt: at,
    );
    final imported = await ingestSms(
      repo,
      body: debit,
      sender: 'VM-HDFCBK',
      receivedAt: at,
      source: 'import',
    );
    expect(live!.decision, Decision.accept);
    expect(imported, isNull);
    expect(await repo.count(), 1);
  });

  test('OTP and loan spam store nothing', () async {
    expect(
      await ingestSms(
        repo,
        body: '1234 is your OTP for Rs 500',
        sender: 'X',
        receivedAt: at,
      ),
      isNull,
    );
    expect(
      await ingestSms(
        repo,
        body:
            'Get instant loan of Rs 5,00,000! Pre-approved. Apply now https://bit.ly/x',
        sender: 'VM-LOANS',
        receivedAt: at,
      ),
      isNull,
    );
    expect(await repo.count(includeDeleted: true), 0);
  });

  test('credit stored as credit', () async {
    await ingestSms(
      repo,
      body: 'Rs 1000 credited to a/c XX1 by NEFT Ref 99887766',
      sender: 'B',
      receivedAt: at,
    );
    final r = (await repo.getRange(all.$1, all.$2)).single;
    expect(r.type, 'credit');
    expect(r.amountMinor, 100000);
  });

  test('uncertain -> review queue, excluded from totals', () async {
    final r = await ingestSms(
      repo,
      body: unsure,
      sender: 'VM-NFLX',
      receivedAt: at,
    );
    expect(r!.decision, Decision.review);
    expect(await repo.getRange(all.$1, all.$2), isEmpty);
    expect((await repo.reviewQueue()).length, 1);
  });

  test(
    'review decision learns a rule and auto-applies to queue + future',
    () async {
      await ingestSms(repo, body: unsure, sender: 'VM-NFLX', receivedAt: at);
      await ingestSms(
        repo,
        body: 'Rs 649 towards your Netflix subscription',
        sender: 'AD-NFLX',
        receivedAt: at.add(const Duration(days: 1)),
      );
      final q = await repo.reviewQueue();
      expect(q.length, 2);

      expect(await repo.resolveReview(q.first.id, 'debit'), 2);
      expect(await repo.reviewQueue(), isEmpty);
      expect((await repo.getRange(all.$1, all.$2)).length, 2);
      final rules = await repo.activeRules();
      expect(rules.values.single, 'debit');

      final next = await ingestSms(
        repo,
        body: 'Rs 199 towards your Netflix subscription',
        sender: 'VM-NFLX',
        receivedAt: at.add(const Duration(days: 30)),
      );
      expect(next!.decision, Decision.accept);
      expect((await repo.getRange(all.$1, all.$2)).length, 3);
    },
  );

  test('ignore decision soft-deletes and future matches are dropped', () async {
    await ingestSms(repo, body: unsure, sender: 'VM-NFLX', receivedAt: at);
    final q = await repo.reviewQueue();
    await repo.resolveReview(q.single.id, 'ignore');
    expect(await repo.reviewQueue(), isEmpty);
    expect(await repo.getRange(all.$1, all.$2), isEmpty);
    expect(
      await ingestSms(
        repo,
        body: 'Rs 10 towards your Netflix subscription',
        sender: 'VM-NFLX',
        receivedAt: at.add(const Duration(days: 2)),
      ),
      isNull,
    );
  });

  test('deleting a rule stops auto-apply', () async {
    await ingestSms(repo, body: unsure, sender: 'VM-NFLX', receivedAt: at);
    await repo.resolveReview((await repo.reviewQueue()).single.id, 'debit');
    final rule = (await repo.watchRules().first).single;
    expect(rule.sample, contains('<amt>'));
    await repo.deleteRule(rule.id);
    expect(await repo.activeRules(), isEmpty);
    final r = await ingestSms(
      repo,
      body: 'Rs 5 towards your Netflix subscription',
      sender: 'VM-NFLX',
      receivedAt: at.add(const Duration(days: 3)),
    );
    expect(r!.decision, Decision.review);
  });
}
