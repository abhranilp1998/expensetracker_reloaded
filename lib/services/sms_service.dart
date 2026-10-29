import 'package:another_telephony/telephony.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db/db_instance.dart';
import '../data/repositories/transaction_repository.dart';
import '../domain/sms/sms_classifier.dart';
import 'notification_service.dart';
import 'sms_ingest.dart';

/// Background entry point. Must stay top-level with the pragma.
/// Runs in a separate isolate with its own DB connection. Never logs bodies.
@pragma('vm:entry-point')
Future<void> smsBackgroundHandler(SmsMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await SmsService.handle(message);
}

/// Reads the SMS inbox and registers the background SMS listener.
class SmsService {
  static final Telephony _telephony = Telephony.instance;
  static bool _listening = false;
  static const importDoneKey = 'smsInboxImportV1';
  static const importWindow = Duration(days: 180);

  static Future<bool> hasPermission() => Permission.sms.isGranted;

  static Future<void> handle(SmsMessage m) async {
    final body = m.body;
    if (body == null || body.isEmpty) return;
    try {
      final p = await ingestSms(
        TransactionRepository(appDatabase),
        body: body,
        sender: m.address ?? '',
        receivedAt: m.date != null
            ? DateTime.fromMillisecondsSinceEpoch(m.date!)
            : DateTime.now(),
      );
      if (p != null) {
        await NotificationService.show(
          p.decision == Decision.review
              ? 'Needs review'
              : 'Transaction detected',
          describe(p),
          key: p.dedupeHash,
        );
      }
    } catch (_) {
      // Swallow: a bad SMS must never crash the receiver.
    }
  }

  /// Register the foreground + background listener once per process.
  static Future<void> start() async {
    if (_listening || !await hasPermission()) return;
    _telephony.listenIncomingSms(
      onNewMessage: handle,
      onBackgroundMessage: smsBackgroundHandler,
      listenInBackground: true,
    );
    _listening = true;
  }

  /// One-time import of inbox SMS from the last [importWindow], through the
  /// same parser + dedupe. Returns number of new rows, or null if skipped.
  static Future<int?> importInboxOnce() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(importDoneKey) ?? false) return null;
    if (!await hasPermission()) return null;
    final since = DateTime.now().subtract(importWindow).millisecondsSinceEpoch;
    final msgs = await _telephony.getInboxSms(
      columns: const [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      filter: SmsFilter.where(SmsColumn.DATE).greaterThan('$since'),
    );
    final repo = TransactionRepository(appDatabase);
    final rules = await repo.activeRules();
    var added = 0;
    for (final m in msgs) {
      final body = m.body;
      if (body == null) continue;
      final p = await ingestSms(
        repo,
        body: body,
        sender: m.address ?? '',
        receivedAt: DateTime.fromMillisecondsSinceEpoch(m.date ?? 0),
        source: 'import',
        rules: rules,
      );
      if (p != null) added++;
    }
    await prefs.setBool(importDoneKey, true);
    return added;
  }
}
