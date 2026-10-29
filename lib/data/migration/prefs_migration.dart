import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/transaction_repository.dart';

/// Outcome of migrating legacy SharedPreferences data into Drift.
class PrefsMigrationResult {
  final int migrated;
  final int skipped;
  final bool alreadyDone;
  const PrefsMigrationResult(
    this.migrated,
    this.skipped, {
    this.alreadyDone = false,
  });
}

/// One-time move of legacy SharedPreferences transactions into SQLite.
/// Legacy rows are all debits ({amount: double, time: ISO8601, message}).
class PrefsMigration {
  static const doneKey = 'migratedV1';
  static const legacyTransactionsKey = 'transactions';
  static const legacyTodayTotalKey = 'todayTotal';

  static Future<PrefsMigrationResult> run(
    SharedPreferences prefs,
    TransactionRepository repo,
  ) async {
    if (prefs.getBool(doneKey) ?? false) {
      return const PrefsMigrationResult(0, 0, alreadyDone: true);
    }
    final raw = prefs.getStringList(legacyTransactionsKey) ?? const [];
    final items = <NewTxn>[];
    var skipped = 0;
    for (final s in raw) {
      try {
        final m = Map<String, dynamic>.from(jsonDecode(s) as Map);
        final amount = (m['amount'] as num).toDouble();
        final time = DateTime.parse(m['time'].toString());
        final msg = (m['message'] ?? '').toString();
        final minor = (amount * 100).round();
        if (minor <= 0) {
          skipped++;
          continue;
        }
        items.add(
          NewTxn(
            amountMinor: minor,
            type: 'debit',
            source: 'migrated',
            occurredAt: time,
            rawBody: msg.isEmpty ? null : msg,
            dedupeHash: sha1
                .convert(
                  utf8.encode('legacy|${time.toIso8601String()}|$minor|$msg'),
                )
                .toString(),
          ),
        );
      } catch (_) {
        skipped++;
      }
    }
    final migrated = await repo.insertAll(items);
    await prefs.setBool(doneKey, true);
    await prefs.remove(legacyTransactionsKey);
    await prefs.remove(legacyTodayTotalKey);
    return PrefsMigrationResult(migrated, skipped);
  }
}
