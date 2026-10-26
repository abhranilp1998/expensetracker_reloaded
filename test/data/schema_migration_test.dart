import 'package:drift/native.dart';
import 'package:expensetracker_reloaded/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('v1 -> v2 adds review columns and rules table, keeps rows', () async {
    final raw = sqlite3.openInMemory();
    raw.execute('''
      CREATE TABLE transactions (id TEXT NOT NULL PRIMARY KEY, amount_minor INTEGER NOT NULL,
        type TEXT NOT NULL, source TEXT NOT NULL, occurred_at INTEGER NOT NULL,
        raw_body TEXT, sender TEXT, merchant TEXT, note TEXT, dedupe_hash TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL,
        deleted INTEGER NOT NULL DEFAULT 0, sync_status TEXT NOT NULL DEFAULT 'pending',
        schema_version INTEGER NOT NULL DEFAULT 1);
      INSERT INTO transactions (id, amount_minor, type, source, occurred_at, dedupe_hash, created_at, updated_at)
        VALUES ('a', 100, 'debit', 'manual', 0, 'h', 0, 0);
      PRAGMA user_version = 1;
    ''');
    final db = AppDatabase(NativeDatabase.opened(raw));
    final rows = await db.select(db.transactions).get();
    expect(rows.single.status, 'confirmed');
    expect(await db.select(db.learnedRules).get(), isEmpty);
    final cols = await db.customSelect('PRAGMA table_info(transactions)').get();
    expect(
      cols.map((c) => c.data['name']),
      containsAll(['status', 'template_key', 'confidence']),
    );
    expect(db.schemaVersion, 2);
    await db.close();
  });
}
