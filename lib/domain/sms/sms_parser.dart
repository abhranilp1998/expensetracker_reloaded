import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'parsed_sms.dart';

/// Pure-Dart SMS parser: amount extraction, debit/credit classification,
/// OTP/promo/balance/failed exclusion and a stable dedupe hash.
/// Accepts all senders. Never logs message bodies.
class SmsParser {
  const SmsParser();

  static final _amount = RegExp(
    r'(?:₹|\brs\.?|\binr)\s*((?:\d{1,3}(?:,\d{2,3})+|\d+)(?:\.\d{1,2})?)(?![\d,])',
    caseSensitive: false,
  );

  /// Fallback for formats without a currency marker, e.g. SBI "debited by 450.0".
  static final _bareAmount = RegExp(
    r'\b(?:debited|credited)\s+(?:by|with|for)\s+((?:\d{1,3}(?:,\d{2,3})+|\d+)(?:\.\d{1,2})?)(?![\d,])',
    caseSensitive: false,
  );

  static final _otp = RegExp(
    r'\b(otp|one[\s-]?time\s+password|verification\s+code|do\s+not\s+share)\b',
    caseSensitive: false,
  );

  static final _promo = RegExp(
    r'\b(offer|cashback\s+(?:up\s*to|upto)|win|won|congratulations|pre[\s-]?approved|loan\s+(?:approved|offer)|apply\s+now|discount|voucher|limited\s+period|click\s+here)\b',
    caseSensitive: false,
  );

  static final _reminder = RegExp(
    r'\b(is\s+due|due\s+(?:on|by|date)|payment\s+due|emi\s+(?:of|on|due)|minimum\s+(?:amount\s+)?due|bill\s+(?:generated|due)|will\s+be\s+(?:debited|deducted)|requested\s+money|collect\s+request)\b',
    caseSensitive: false,
  );

  static final _failed = RegExp(
    r'\b(failed|declined|unsuccessful|reversed\s+due|could\s+not\s+be\s+processed|insufficient)\b',
    caseSensitive: false,
  );

  static final _credit = RegExp(
    r'\b(credited|received|refund(?:ed)?|deposited|cashback\s+of|reversed|added\s+to)\b',
    caseSensitive: false,
  );

  static final _debit = RegExp(
    r'\b(debited|spent|paid|sent|withdrawn|withdrawal|purchase|deducted|debit(?:ed)?\s+for|transferred\s+to|used\s+(?:at|for|on))\b',
    caseSensitive: false,
  );

  static final _balancePrefix = RegExp(
    r'(?:avl|avail(?:able)?|a/?c|acct|total|closing|current)?\.?\s*(?:bal(?:ance)?|bal\.?|limit)\s*(?:is|:|-|of)?\s*(?:₹|rs\.?|inr)?\s*$',
    caseSensitive: false,
  );

  /// Bank reference: the id after Ref/UPI/Txn/UTR. It must contain a digit,
  /// so plain words ('UPI payment') are never a reference (Codex A2).
  static final _ref = RegExp(
    r'\b(?:ref(?:erence)?\.?\s*(?:no\.?|number|#)?|upi\s*(?:ref|txn)?\s*(?:no\.?|id)?|txn\s*(?:id|no\.?)?|utr)\s*[:\-]?\s*((?=[A-Za-z0-9]*\d)[A-Za-z0-9]{6,})',
    caseSensitive: false,
  );

  static final _merchant = RegExp(
    r'\b(?:at|to|towards|on)\s+([A-Za-z0-9&.\- ]{2,40}?)(?=\s+(?:on|via|ref|upi|for|avl|from|using|\.|,)|[.,]|$)',
    caseSensitive: false,
  );

  ParsedSms? parse({
    required String body,
    required String sender,
    required DateTime receivedAt,
  }) {
    try {
      final text = body.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isEmpty) return null;
      if (_otp.hasMatch(text) ||
          _failed.hasMatch(text) ||
          _reminder.hasMatch(text)) {
        return null;
      }

      final isCredit = _credit.firstMatch(text);
      final isDebit = _debit.firstMatch(text);
      if (isCredit == null && isDebit == null) return null; // promos, info
      if (_promo.hasMatch(text) && !_looksTransactional(text)) return null;

      final TxnType type;
      if (isCredit != null && isDebit != null) {
        // "debited ... credited to X" (transfer out) vs "credited ... debited from X".
        type = isDebit.start <= isCredit.start ? TxnType.debit : TxnType.credit;
      } else {
        type = isDebit != null ? TxnType.debit : TxnType.credit;
      }

      final amountMinor = _firstTxnAmount(text);
      if (amountMinor == null || amountMinor <= 0) return null;

      final reference = _ref.firstMatch(text)?.group(1);
      final merchant = _merchant.firstMatch(text)?.group(1)?.trim();

      return ParsedSms(
        amountMinor: amountMinor,
        type: type,
        sender: sender,
        receivedAt: receivedAt,
        reference: reference,
        merchant: (merchant == null || merchant.isEmpty) ? null : merchant,
        dedupeHash: dedupeHash(
          sender: sender,
          amountMinor: amountMinor,
          type: type,
          reference: reference,
          body: text,
          at: receivedAt,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Loose extraction with no exclusions, used by [SmsClassifier] to queue
  /// uncertain messages for review.
  RawExtraction extract(String body) {
    final text = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    final c = _credit.firstMatch(text);
    final d = _debit.firstMatch(text);
    TxnType? type;
    if (c != null && d != null) {
      type = d.start <= c.start ? TxnType.debit : TxnType.credit;
    } else if (d != null) {
      type = TxnType.debit;
    } else if (c != null) {
      type = TxnType.credit;
    }
    return RawExtraction(
      text: text,
      amountMinor: _firstTxnAmount(text),
      typeGuess: type,
      reference: _ref.firstMatch(text)?.group(1),
      merchant: _merchant.firstMatch(text)?.group(1)?.trim(),
      isOtp: _otp.hasMatch(text),
      isFailed: _failed.hasMatch(text),
      isReminder: _reminder.hasMatch(text),
    );
  }

  bool _looksTransactional(String t) => RegExp(
    r'\b(a/?c|acct|account|card|upi)\b',
    caseSensitive: false,
  ).hasMatch(t);

  /// First amount not immediately preceded by a balance/limit phrase.
  int? _firstTxnAmount(String text) {
    for (final m in _amount.allMatches(text)) {
      final before = text.substring(0, m.start);
      final window = before.length > 30
          ? before.substring(before.length - 30)
          : before;
      if (_balancePrefix.hasMatch(window)) {
        continue;
      }
      final v = toMinor(m.group(1)!);
      if (v != null) return v;
    }
    final bare = _bareAmount.firstMatch(text);
    return bare == null ? null : toMinor(bare.group(1)!);
  }

  static int? toMinor(String raw) {
    final cleaned = raw.replaceAll(',', '');
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(cleaned)) return null;
    final parts = cleaned.split('.');
    final rupees = int.parse(parts[0]);
    final paise = parts.length > 1 ? int.parse(parts[1].padRight(2, '0')) : 0;
    return rupees * 100 + paise;
  }

  /// Stable across re-reads of the same SMS (live listener vs inbox import).
  static String dedupeHash({
    required String sender,
    required int amountMinor,
    required TxnType type,
    required String? reference,
    required String body,
    required DateTime at,
  }) {
    final minuteBucket = at.toUtc().millisecondsSinceEpoch ~/ 60000;
    final key = reference != null
        ? '${sender.toUpperCase()}|$amountMinor|${type.name}|$reference'
        : '${sender.toUpperCase()}|$amountMinor|${type.name}|${body.toLowerCase()}|$minuteBucket';
    return sha1.convert(utf8.encode(key)).toString();
  }
}

/// Fields (amount, direction, merchant, account) extracted from one SMS body.
class RawExtraction {
  final String text;
  final int? amountMinor;
  final TxnType? typeGuess;
  final String? reference;
  final String? merchant;
  final bool isOtp;
  final bool isFailed;
  final bool isReminder;
  const RawExtraction({
    required this.text,
    required this.amountMinor,
    required this.typeGuess,
    required this.reference,
    required this.merchant,
    required this.isOtp,
    required this.isFailed,
    required this.isReminder,
  });
}
