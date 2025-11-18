// SMS service abstraction (placeholder)
//
// The current project handles SMS parsing and listening inside
// `lib/home_dashboard.dart`. To make SMS behavior testable and reusable, move
// listening/parsing logic into this service. Keep the background handler
// (`@pragma('vm:entry-point') backgroundMessageHandler`) in `main.dart` or
// move it here and preserve the pragma.

// Example API to implement:
// class SmsService {
//   Future<void> startListening(void Function(String) onMessage);
//   RegExp amountRegex = RegExp(r"(?:rs\.?|inr)\s*([0-9,]+\.?[0-9]*)", caseSensitive: false);
// }



import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
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
          final transaction = _parseMessage(message.body!);
          if (transaction != null) {
            onTransactionDetected(transaction);
          }
        }
      },
    );
  }

  static TransactionModel? _parseMessage(String text) {
    try {
      final regex = RegExp(
        r'(?:rs\.?|inr)\s*([0-9,]+\.?[0-9]*)',
        caseSensitive: false,
      );
      final match = regex.firstMatch(text);
      
      if (match != null) {
        final amount = double.parse(match.group(1)!.replaceAll(',', ''));
        return TransactionModel(
          amount: amount,
          time: DateTime.now(),
          message: text,
        );
      }
    } catch (e) {
      debugPrint('Error parsing SMS: $e');
    }
    return null;
  }

  static TransactionModel? parseManualMessage(String text) {
    return _parseMessage(text);
  }
}