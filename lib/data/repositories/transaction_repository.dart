import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';

typedef Clock = DateTime Function();

class NewTxn {
  final int amountMinor;
  final String type;
  final String source;
  final DateTime occurredAt;
  final String dedupeHash;
  final String? rawBody;
  final String? sender;
  final String? merchant;
  final String? note;

  const NewTxn({
    required this.amountMinor,
    required this.type,
    required this.source,
    required this.occurredAt,
    required this.dedupeHash,
    this.rawBody,
    this.sender,
    this.merchant,
    this.note,
  });
}

class TransactionRepository {
  TransactionRepository(this._db, {Clock? clock, Uuid? uuid})
    : _clock = clock ?? DateTime.now,
      _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Clock _clock;
  final Uuid _uuid;

  int get _nowMs => _clock().toUtc().millisecondsSinceEpoch;

  TransactionsCompanion _companion(NewTxn t) {
    final now = _nowMs;
    return TransactionsCompanion.insert(
      id: _uuid.v4(),
      amountMinor: t.amountMinor,
      type: t.type,
      source: t.source,
      occurredAt: t.occurredAt.toUtc().millisecondsSinceEpoch,
      dedupeHash: t.dedupeHash,
      rawBody: Value(t.rawBody),
      sender: Value(t.sender),
      merchant: Value(t.merchant),
      note: Value(t.note),
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Returns true if inserted, false if a row with the same dedupe hash exists.
  Future<bool> insert(NewTxn t) => _db.transaction(() async {
    final existing = await (_db.select(
      _db.transactions,
    )..where((x) => x.dedupeHash.equals(t.dedupeHash))).getSingleOrNull();
    if (existing != null) return false;
    await _db.into(_db.transactions).insert(_companion(t));
    return true;
  });

  /// Bulk insert ignoring duplicates. Returns the number of new rows.
  Future<int> insertAll(Iterable<NewTxn> items) async {
    final before = await count(includeDeleted: true);
    await _db.batch((b) {
      b.insertAll(
        _db.transactions,
        items.map(_companion).toList(),
        mode: InsertMode.insertOrIgnore,
      );
    });
    return await count(includeDeleted: true) - before;
  }

  Future<int> count({bool includeDeleted = false}) async {
    final c = _db.transactions.id.count();
    final q = _db.selectOnly(_db.transactions)..addColumns([c]);
    if (!includeDeleted) q.where(_db.transactions.deleted.equals(false));
    return (await q.getSingle()).read(c) ?? 0;
  }

  SimpleSelectStatement<$TransactionsTable, TxnRow> _range(
    DateTime from,
    DateTime to,
  ) {
    final f = from.toUtc().millisecondsSinceEpoch;
    final t = to.toUtc().millisecondsSinceEpoch;
    return _db.select(_db.transactions)
      ..where(
        (x) =>
            x.deleted.equals(false) &
            x.occurredAt.isBiggerOrEqualValue(f) &
            x.occurredAt.isSmallerThanValue(t),
      )
      ..orderBy([(x) => OrderingTerm.desc(x.occurredAt)]);
  }

  /// Non-deleted rows with from <= occurredAt < to, newest first.
  Stream<List<TxnRow>> watchRange(DateTime from, DateTime to) =>
      _range(from, to).watch();

  Future<List<TxnRow>> getRange(DateTime from, DateTime to) =>
      _range(from, to).get();

  Stream<List<TxnRow>> watchAll() =>
      (_db.select(_db.transactions)
            ..where((x) => x.deleted.equals(false))
            ..orderBy([(x) => OrderingTerm.desc(x.occurredAt)]))
          .watch();

  Future<void> softDelete(String id) =>
      (_db.update(_db.transactions)..where((x) => x.id.equals(id))).write(
        TransactionsCompanion(
          deleted: const Value(true),
          updatedAt: Value(_nowMs),
          syncStatus: const Value('pending'),
        ),
      );

  Future<void> updateTxn(
    String id, {
    int? amountMinor,
    String? type,
    String? note,
    String? merchant,
  }) => (_db.update(_db.transactions)..where((x) => x.id.equals(id))).write(
    TransactionsCompanion(
      amountMinor: Value.absentIfNull(amountMinor),
      type: Value.absentIfNull(type),
      note: Value.absentIfNull(note),
      merchant: Value.absentIfNull(merchant),
      updatedAt: Value(_nowMs),
      syncStatus: const Value('pending'),
    ),
  );

  Future<TxnRow?> byId(String id) => (_db.select(
    _db.transactions,
  )..where((x) => x.id.equals(id))).getSingleOrNull();
}
