import 'package:another_telephony/telephony.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db/db_instance.dart';
import '../data/repositories/transaction_repository.dart';
import '../domain/sms/sms_classifier.dart';
import 'notification_service.dart';
import 'sms_import.dart';
import 'sms_ingest.dart';

export 'sms_import.dart' show ImportSummary, ImportCancelToken;

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

  /// Default range offered on the scan screen.
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

  /// True once an inbox scan finished (not cancelled, not failed).
  static Future<bool> importDone() async =>
      (await SharedPreferences.getInstance()).getBool(importDoneKey) ?? false;

  /// Reads inbox SMS from the last [window]. Never runs on its own: only the
  /// Inbox scan screen calls this, after the user agreed (bugs #12, #13).
  static Future<List<InboxMessage>> readInbox(Duration window) async {
    final since = DateTime.now().subtract(window).millisecondsSinceEpoch;
    final msgs = await _telephony.getInboxSms(
      columns: const [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      filter: SmsFilter.where(SmsColumn.DATE).greaterThan('$since'),
    );
    return [
      for (final m in msgs)
        if (m.body != null && m.body!.isNotEmpty)
          InboxMessage(
            address: m.address ?? '',
            body: m.body!,
            date: DateTime.fromMillisecondsSinceEpoch(m.date ?? 0),
          ),
    ];
  }

  /// Scans the inbox and stores transactions. Marks the import as done only
  /// when it ran to the end; a cancel or an error leaves it not done.
  static Future<ImportSummary> scanInbox(
    Duration window, {
    void Function(int done, int total)? onProgress,
    ImportCancelToken? cancel,
  }) async {
    if (!await hasPermission()) {
      throw StateError('SMS permission is not granted');
    }
    final msgs = await readInbox(window);
    final summary = await importMessages(
      TransactionRepository(appDatabase),
      msgs,
      onProgress: onProgress,
      cancel: cancel,
    );
    if (!summary.cancelled) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(importDoneKey, true);
    }
    return summary;
  }
}
