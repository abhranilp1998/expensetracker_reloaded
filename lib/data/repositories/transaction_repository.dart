import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/sms/sms_template.dart';
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
  final String status;
  final String? templateKey;
  final double? confidence;

  const NewTxn({
    this.status = 'confirmed',
    this.templateKey,
    this.confidence,
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
      status: Value(t.status),
      templateKey: Value(t.templateKey),
      confidence: Value(t.confidence),
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
            x.status.equals('confirmed') &
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
            ..where(
              (x) => x.deleted.equals(false) & x.status.equals('confirmed'),
            )
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

  /// Manually entered transaction (amount in rupees).
  Future<bool> addManual({
    required double amount,
    String type = 'debit',
    String? note,
    DateTime? at,
  }) {
    final when = at ?? _clock();
    final minor = (amount * 100).round();
    return insert(NewTxn(
      amountMinor: minor,
      type: type,
      source: 'manual',
      occurredAt: when,
      note: note,
      dedupeHash: 'manual:${_uuid.v4()}',
    ));
  }

  /// Soft-deletes every transaction (sync-friendly reset).
  Future<void> softDeleteAll() =>
      (_db.update(_db.transactions)..where((x) => x.deleted.equals(false)))
          .write(TransactionsCompanion(
        deleted: const Value(true),
        updatedAt: Value(_nowMs),
        syncStatus: const Value('pending'),
      ));

  // ---- Review queue -------------------------------------------------------

  Stream<List<TxnRow>> watchReviewQueue() => (_db.select(_db.transactions)
        ..where((x) => x.deleted.equals(false) & x.status.equals('review'))
        ..orderBy([(x) => OrderingTerm.desc(x.occurredAt)]))
      .watch();

  Future<List<TxnRow>> reviewQueue() => (_db.select(_db.transactions)
        ..where((x) => x.deleted.equals(false) & x.status.equals('review')))
      .get();

  /// Applies the user's decision to [id] and every other queued row with the
  /// same template, and stores it as a rule for future SMS.
  /// [action] is 'debit' | 'credit' | 'ignore'. Returns rows resolved.
  Future<int> resolveReview(String id, String action) =>
      _db.transaction(() async {
        final row = await byId(id);
        if (row == null) return 0;
        final key = row.templateKey;
        if (key != null) {
          await upsertRule(
              templateKey: key,
              sender: row.sender ?? '',
              action: action,
              sample: row.rawBody == null ? null : normalizeTemplate(row.rawBody!));
        }
        final targets = key == null
            ? [row]
            : await (_db.select(_db.transactions)
                  ..where((x) =>
                      x.deleted.equals(false) &
                      x.status.equals('review') &
                      x.templateKey.equals(key)))
                .get();
        for (final t in targets) {
          await (_db.update(_db.transactions)..where((x) => x.id.equals(t.id)))
              .write(TransactionsCompanion(
            status: const Value('confirmed'),
            type: action == 'ignore' ? const Value.absent() : Value(action),
            deleted: Value(action == 'ignore'),
            updatedAt: Value(_nowMs),
            syncStatus: const Value('pending'),
          ));
        }
        return targets.length;
      });

  // ---- Learned rules ------------------------------------------------------

  Future<void> upsertRule({
    required String templateKey,
    required String sender,
    required String action,
    String? sample,
  }) async {
    final now = _nowMs;
    final existing = await (_db.select(_db.learnedRules)
          ..where((r) => r.templateKey.equals(templateKey)))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.learnedRules).insert(LearnedRulesCompanion.insert(
            id: _uuid.v4(),
            templateKey: templateKey,
            sender: sender,
            action: action,
            sample: Value(sample),
            createdAt: now,
            updatedAt: now,
          ));
    } else {
      await (_db.update(_db.learnedRules)
            ..where((r) => r.id.equals(existing.id)))
          .write(LearnedRulesCompanion(
        action: Value(action),
        sample: sample == null ? const Value.absent() : Value(sample),
        deleted: const Value(false),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ));
    }
  }

  Future<Map<String, String>> activeRules() async {
    final rows = await (_db.select(_db.learnedRules)
          ..where((r) => r.deleted.equals(false)))
        .get();
    return {for (final r in rows) r.templateKey: r.action};
  }

  Stream<List<RuleRow>> watchRules() => (_db.select(_db.learnedRules)
        ..where((r) => r.deleted.equals(false))
        ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]))
      .watch();

  Future<void> deleteRule(String id) =>
      (_db.update(_db.learnedRules)..where((r) => r.id.equals(id))).write(
        LearnedRulesCompanion(
          deleted: const Value(true),
          updatedAt: Value(_nowMs),
          syncStatus: const Value('pending'),
        ),
      );
}
