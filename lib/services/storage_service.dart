import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../data/db/app_database.dart';
import '../data/db/db_instance.dart';
import '../data/repositories/transaction_repository.dart';

/// Map shape the legacy screens render. Removed when screens consume
/// [TxnRow] directly (P7).
Map<String, dynamic> txnToMap(TxnRow r) => {
  'id': r.id,
  'amount': r.amountMinor / 100,
  'type': r.type,
  'time': DateTime.fromMillisecondsSinceEpoch(r.occurredAt).toIso8601String(),
  'message': r.note ?? r.merchant ?? r.rawBody ?? '',
};

/// Thin bridge from legacy screens to the SQLite repository.
class StorageService {
  static TransactionRepository get _repo => TransactionRepository(appDatabase);

  static Future<List<TxnRow>> _all() =>
      _repo.getRange(DateTime.utc(1970), DateTime.utc(3000));

  /// Oldest first (legacy order).
  static Future<List<Map<String, dynamic>>> getTransactions() async =>
      (await _all()).reversed.map(txnToMap).toList();

  /// Sum of debits after [since].
  static Future<double> calculateTotal(DateTime since) async {
    final ms = since.toUtc().millisecondsSinceEpoch;
    return (await _all())
            .where((r) => r.type == 'debit' && r.occurredAt > ms)
            .fold<int>(0, (s, r) => s + r.amountMinor) /
        100;
  }

  static Future<bool> addManual({
    required double amount,
    String type = 'debit',
    String? note,
    DateTime? at,
  }) {
    final when = at ?? DateTime.now();
    final minor = (amount * 100).round();
    return _repo.insert(
      NewTxn(
        amountMinor: minor,
        type: type,
        source: 'manual',
        occurredAt: when,
        note: note,
        dedupeHash: sha1
            .convert(
              utf8.encode(
                'manual|${when.microsecondsSinceEpoch}|$minor|$type|${note ?? ''}',
              ),
            )
            .toString(),
      ),
    );
  }

  /// Soft-deletes everything (sync-friendly).
  static Future<void> resetAllData() async {
    for (final r in await _all()) {
      await _repo.softDelete(r.id);
    }
  }
}
