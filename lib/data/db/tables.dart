import 'package:drift/drift.dart';

/// Sync-ready transactions table. Amounts in minor units (paise).
/// Times stored as UTC epoch ms.
@DataClassName('TxnRow')
class Transactions extends Table {
  TextColumn get id => text()(); // uuid v4
  IntColumn get amountMinor => integer()();
  TextColumn get type => text()(); // 'debit' | 'credit'
  TextColumn get source => text()(); // 'sms' | 'manual' | 'migrated' | 'import'
  IntColumn get occurredAt => integer()();
  TextColumn get rawBody => text().nullable()();
  TextColumn get sender => text().nullable()();
  TextColumn get merchant => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get dedupeHash => text().unique()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))(); // 'pending' | 'synced'
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();
  // v2: review queue. 'confirmed' rows count in totals; 'review' rows don't.
  TextColumn get status => text().withDefault(const Constant('confirmed'))();
  TextColumn get templateKey => text().nullable()();
  RealColumn get confidence => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// v2: on-device rules learned from the user's review decisions.
/// Keyed on sha1(normalized sender | masked template). No message text stored.
@DataClassName('RuleRow')
class LearnedRules extends Table {
  TextColumn get id => text()();
  TextColumn get templateKey => text().unique()();
  TextColumn get sender => text()();
  TextColumn get action => text()(); // 'debit' | 'credit' | 'ignore'
  TextColumn get sample => text().nullable()(); // masked template, for the UI
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
