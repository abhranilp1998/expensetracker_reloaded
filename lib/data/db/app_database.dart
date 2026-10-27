import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Transactions, LearnedRules])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  static QueryExecutor _open() => driftDatabase(
    name: 'ledgerly',
    // Background SMS isolate and UI share the file; drift_flutter enables WAL.
    native: const DriftNativeOptions(shareAcrossIsolates: true),
  );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_txn_occurred ON transactions (occurred_at)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_txn_deleted ON transactions (deleted)',
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(transactions, transactions.status);
        await m.addColumn(transactions, transactions.templateKey);
        await m.addColumn(transactions, transactions.confidence);
        await m.createTable(learnedRules);
      }
    },
  );
}
