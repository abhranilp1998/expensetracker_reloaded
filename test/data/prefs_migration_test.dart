import 'dart:convert';

import 'package:drift/native.dart';
import 'package:expensetracker_reloaded/data/db/app_database.dart';
import 'package:expensetracker_reloaded/data/migration/prefs_migration.dart';
import 'package:expensetracker_reloaded/data/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TransactionRepository(db);
  });
  tearDown(() => db.close());

  test('migrates legacy rows, skips bad ones, idempotent', () async {
    SharedPreferences.setMockInitialValues({
      'todayTotal': 170.5,
      'transactions': [
        jsonEncode({
          'amount': 120.5,
          'time': '2026-10-12T10:00:00.000',
          'message': 'Rs 120.5 debited',
        }),
        jsonEncode({
          'amount': 50,
          'time': '2026-10-11T09:00:00.000',
          'message': 'Manual expense',
        }),
        jsonEncode({
          'amount': 50,
          'time': '2026-10-11T09:00:00.000',
          'message': 'Manual expense',
        }), // dup
        'not json',
        jsonEncode({'amount': 'x', 'time': 'bad'}),
      ],
    });
    final prefs = await SharedPreferences.getInstance();
    final r = await PrefsMigration.run(prefs, repo);
    expect(r.migrated, 2);
    expect(r.skipped, 2);
    expect(await repo.count(), 2);
    expect(prefs.getStringList('transactions'), isNull);
    expect(prefs.getDouble('todayTotal'), isNull);
    final rows = await repo.getRange(DateTime.utc(2000), DateTime.utc(2100));
    expect(rows.map((e) => e.amountMinor).toSet(), {12050, 5000});
    expect(
      rows.every((e) => e.source == 'migrated' && e.type == 'debit'),
      isTrue,
    );

    final again = await PrefsMigration.run(prefs, repo);
    expect(again.alreadyDone, isTrue);
    expect(await repo.count(), 2);
  });

  test('empty prefs marks done', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    expect((await PrefsMigration.run(prefs, repo)).migrated, 0);
    expect(prefs.getBool(PrefsMigration.doneKey), isTrue);
  });
}
