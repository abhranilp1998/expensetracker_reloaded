import 'package:drift/native.dart';
import 'package:expensetracker_reloaded/data/db/app_database.dart';
import 'package:expensetracker_reloaded/data/repositories/transaction_repository.dart';
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
  const debit =
      'Rs.250 debited from a/c XX12 to swiggy@icici UPI Ref No 428500009999';

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
    expect(live, isNotNull);
    expect(imported, isNull);
    expect(await repo.count(), 1);
  });

  test('non-transaction SMS stores nothing', () async {
    expect(
      await ingestSms(
        repo,
        body: '1234 is your OTP for Rs 500',
        sender: 'X',
        receivedAt: at,
      ),
      isNull,
    );
    expect(await repo.count(), 0);
  });

  test('credit stored as credit', () async {
    await ingestSms(
      repo,
      body: 'Rs 1000 credited to a/c XX1 by NEFT',
      sender: 'B',
      receivedAt: at,
    );
    final r = (await repo.getRange(DateTime(2000), DateTime(2100))).single;
    expect(r.type, 'credit');
    expect(r.amountMinor, 100000);
  });
}
