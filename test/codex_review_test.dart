import 'package:drift/native.dart';
import 'package:expensetracker_reloaded/data/db/app_database.dart';
import 'package:expensetracker_reloaded/data/repositories/transaction_repository.dart';
import 'package:expensetracker_reloaded/domain/sms/sms_parser.dart';
import 'package:expensetracker_reloaded/services/debug_unlock_service.dart';
import 'package:expensetracker_reloaded/services/sms_ingest.dart';
import 'package:expensetracker_reloaded/utils/money.dart';
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
}
