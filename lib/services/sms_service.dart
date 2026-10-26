import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import '../domain/sms/parsed_sms.dart';
import '../domain/sms/sms_parser.dart';
import '../models/transaction_model.dart';
// import 'package:intl/intl.dart';

class SmsService {
  static final Telephony _telephony = Telephony.instance;

  static Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  static Future<bool> checkPermission() async {
    final status = await Permission.sms.status;
    return status.isGranted;
  }

  static void listenForSms(Function(TransactionModel) onTransactionDetected) {
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        if (message.body != null) {
          final transaction =
              _parseMessage(message.body!, sender: message.address ?? '');
          if (transaction != null) {
            onTransactionDetected(transaction);
          }
        }
      },
    );
  }

  static TransactionModel? _parseMessage(String text, {String sender = ''}) {
    final parsed = const SmsParser()
        .parse(body: text, sender: sender, receivedAt: DateTime.now());
    if (parsed == null || parsed.type != TxnType.debit) return null;
    return TransactionModel(
      amount: parsed.amount,
      time: parsed.receivedAt,
      message: text,
    );
  }

  static TransactionModel? parseManualMessage(String text) {
    return _parseMessage(text);
  }
}