import 'package:drift/native.dart';
import 'package:expensetracker_reloaded/data/db/app_database.dart';
import 'package:expensetracker_reloaded/data/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repo;
  var now = DateTime.utc(2026, 10, 12, 10);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TransactionRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  NewTxn txn(String hash, {int amount = 1000, DateTime? at}) => NewTxn(
    amountMinor: amount,
    type: 'debit',
    source: 'manual',
    occurredAt: at ?? now,
    dedupeHash: hash,
  );

  test('insert, duplicate ignored', () async {
    expect(await repo.insert(txn('a')), isTrue);
    expect(await repo.insert(txn('a')), isFalse);
    expect(await repo.count(), 1);
  });

  test('insertAll ignores duplicates and returns new count', () async {
    await repo.insert(txn('a'));
    expect(await repo.insertAll([txn('a'), txn('b'), txn('c')]), 2);
  });

  test('ids are uuids and sync fields default', () async {
    await repo.insert(txn('a'));
    final r = (await repo.getRange(
      DateTime.utc(2000),
      DateTime.utc(2100),
    )).single;
    expect(r.id, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(r.deleted, isFalse);
    expect(r.syncStatus, 'pending');
    expect(r.createdAt, r.updatedAt);
  });

  test('soft delete hides row; update bumps updatedAt', () async {
    await repo.insert(txn('a'));
    await repo.insert(txn('b'));
    final rows = await repo.getRange(DateTime.utc(2000), DateTime.utc(2100));
    now = now.add(const Duration(minutes: 1));
    await repo.updateTxn(rows.first.id, note: 'edited');
    final edited = await repo.byId(rows.first.id);
    expect(edited!.updatedAt, greaterThan(edited.createdAt));
    expect(edited.note, 'edited');
    await repo.softDelete(rows.last.id);
    expect(await repo.count(), 1);
    expect((await repo.byId(rows.last.id))!.deleted, isTrue);
  });

  test('range is [from, to)', () async {
    final d = DateTime.utc(2026, 10, 12);
    await repo.insert(txn('a', at: d));
    await repo.insert(txn('b', at: d.add(const Duration(days: 1))));
    final r = await repo.getRange(d, d.add(const Duration(days: 1)));
    expect(r.map((e) => e.dedupeHash), ['a']);
  });
}
