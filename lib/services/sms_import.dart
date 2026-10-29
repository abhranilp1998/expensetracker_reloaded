import 'package:flutter/foundation.dart';
import '../data/repositories/transaction_repository.dart';
import 'sms_ingest.dart';

/// One inbox SMS, decoupled from the telephony plugin so import is testable.
class InboxMessage {
  const InboxMessage({
    required this.address,
    required this.body,
    required this.date,
  });
  final String address;
  final String body;
  final DateTime date;
}

/// Counts shown on the import summary screen.
class ImportSummary {
  int scanned = 0; // messages read from the inbox
  int added = 0; // new confirmed transactions
  int review = 0; // new rows waiting in the Review tab
  int duplicates = 0; // already stored earlier (re-scan)
  int skipped = 0; // not transactions (OTP, promo, ignored...)
  int errors = 0; // messages that could not be read (malformed); scan goes on
  bool cancelled = false;

  /// Messages that looked like money movement.
  int get found => added + review + duplicates;

  @override
  String toString() =>
      'ImportSummary(scanned=$scanned, found=$found, added=$added, '
      'review=$review, duplicates=$duplicates, skipped=$skipped, errors=$errors, '
      'cancelled=$cancelled)';
}

/// Set [cancelled] from the UI to stop an import between messages.
class ImportCancelToken {
  bool cancelled = false;
}

/// Runs every message through the normal ingest path (same classifier,
/// same dedupe as live SMS). Safe to run again: duplicates are counted,
/// not stored twice.
Future<ImportSummary> importMessages(
  TransactionRepository repo,
  List<InboxMessage> messages, {
  void Function(int done, int total)? onProgress,
  ImportCancelToken? cancel,
}) async {
  final rules = await repo.activeRules();
  final summary = ImportSummary();
  final total = messages.length;
  for (var i = 0; i < total; i++) {
    if (cancel?.cancelled ?? false) {
      summary.cancelled = true;
      break;
    }
    final m = messages[i];
    summary.scanned++;
    // One bad message must never stop the scan (Codex A3).
    final ({IngestStatus status, IngestResult? result}) r;
    try {
      r = await ingestSmsWithStatus(
        repo,
        body: m.body,
        sender: m.address,
        receivedAt: m.date,
        source: 'import',
        rules: rules,
      );
    } catch (e) {
      debugPrint('inbox import: skipped unreadable SMS from ${m.address}: $e');
      summary.errors++;
      onProgress?.call(i + 1, total);
      continue;
    }
    switch (r.status) {
      case IngestStatus.added:
        summary.added++;
      case IngestStatus.review:
        summary.review++;
      case IngestStatus.duplicate:
        summary.duplicates++;
      case IngestStatus.dropped:
        summary.skipped++;
    }
    onProgress?.call(i + 1, total);
  }
  return summary;
}
