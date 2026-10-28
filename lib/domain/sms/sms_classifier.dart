import 'parsed_sms.dart';
import 'sms_parser.dart';
import 'sms_template.dart';

enum Decision { accept, review, drop }

/// A user decision learned for a sender+template.
enum RuleAction { debit, credit, ignore }

/// Result of classifying a parsed SMS: kind, confidence and whether it needs review.
class Classification {
  final Decision decision;
  final double confidence;
  final String templateKey;
  final int? amountMinor;
  final TxnType? type;
  final String? merchant;
  final String dedupeHash;
  final bool fromRule;

  const Classification({
    required this.decision,
    required this.confidence,
    required this.templateKey,
    required this.dedupeHash,
    this.amountMinor,
    this.type,
    this.merchant,
    this.fromRule = false,
  });
}

/// Confidence scoring on top of [SmsParser], plus learned-rule override.
/// Pure and on-device; never logs message text.
class SmsClassifier {
  const SmsClassifier({this.parser = const SmsParser()});
  final SmsParser parser;

  static const acceptAt = 0.7;
  static const dropBelow = 0.2;

  static final _pastVerb = RegExp(
    r'\b(debited|credited|spent|paid|sent|received|withdrawn|deducted|deposited|refunded|transferred)\b',
    caseSensitive: false,
  );
  static final _acctMask = RegExp(
    r'(?:a/?c|acct|account|card)[^a-z0-9]{0,10}(?:no\.?\s*)?[x*]+\s?\d{2,6}|\b[x*]{2,}\d{2,6}\b',
    caseSensitive: false,
  );
  static final _ref = RegExp(
    r'\b(ref(?:erence)?\s*(?:no|#)?|upi\s*(?:ref|txn)?|utr|txn\s*(?:id|no))\b',
    caseSensitive: false,
  );
  static final _offerWords = RegExp(
    r'\b(get|avail|pre[\s-]?approved|apply\s+now|limit\s+(?:of\s+)?up\s*to|up\s*to|upto|eligible|offer|win|congratulations|claim|instant\s+loan|loan\s+of|click|hurry|limited\s+period|exclusive|unlock|perks?|benefits?|enjoy|free|worth|cashback\s+offer|validity|unlimited|subscribe|membership|recharge\s+now|plans?\s+(?:at|from|starting))\b',
    caseSensitive: false,
  );
  static final _link = RegExp(
    r'https?://|www\.|\b\w+\.(?:in|com|ly|me|it)/\S*',
    caseSensitive: false,
  );

  /// 0..1 score that [text] reports a completed transaction.
  static double score(String text) {
    var s = 0.15; // caller guarantees a currency amount
    if (_pastVerb.hasMatch(text)) s += 0.4;
    if (_acctMask.hasMatch(text)) s += 0.25;
    if (_ref.hasMatch(text)) s += 0.2;
    final offers = _offerWords.allMatches(text).length;
    s -= 0.25 * offers.clamp(0, 3);
    if (_link.hasMatch(text)) s -= 0.2;
    return s.clamp(0.0, 1.0);
  }

  Classification classify({
    required String body,
    required String sender,
    required DateTime receivedAt,
    RuleAction? Function(String templateKey)? ruleFor,
  }) {
    final key = templateKey(sender, body);
    final raw = parser.extract(body);
    final dedupe = SmsParser.dedupeHash(
      sender: sender,
      amountMinor: raw.amountMinor ?? 0,
      type: raw.typeGuess ?? TxnType.debit,
      reference: raw.reference,
      body: raw.text,
      at: receivedAt,
    );

    Classification out(
      Decision d,
      double c, {
      TxnType? type,
      bool rule = false,
      String? hash,
    }) => Classification(
      decision: d,
      confidence: c,
      templateKey: key,
      dedupeHash: hash ?? dedupe,
      amountMinor: raw.amountMinor,
      type: type ?? raw.typeGuess,
      merchant: raw.merchant,
      fromRule: rule,
    );

    // Hard drops: never money movement.
    if (raw.text.isEmpty ||
        raw.amountMinor == null ||
        raw.amountMinor! <= 0 ||
        raw.isOtp) {
      return out(Decision.drop, 0);
    }

    // Learned rule wins.
    final rule = ruleFor?.call(key);
    if (rule != null) {
      if (rule == RuleAction.ignore) return out(Decision.drop, 1, rule: true);
      final t = rule == RuleAction.debit ? TxnType.debit : TxnType.credit;
      return out(
        Decision.accept,
        1,
        type: t,
        rule: true,
        hash: SmsParser.dedupeHash(
          sender: sender,
          amountMinor: raw.amountMinor!,
          type: t,
          reference: raw.reference,
          body: raw.text,
          at: receivedAt,
        ),
      );
    }

    if (raw.isFailed || raw.isReminder) return out(Decision.drop, 0);

    final c = score(raw.text);
    final strict = parser.parse(
      body: body,
      sender: sender,
      receivedAt: receivedAt,
    );
    if (strict != null && c >= acceptAt) {
      return Classification(
        decision: Decision.accept,
        confidence: c,
        templateKey: key,
        dedupeHash: strict.dedupeHash,
        amountMinor: strict.amountMinor,
        type: strict.type,
        merchant: strict.merchant,
      );
    }
    final spammy = _offerWords.hasMatch(raw.text) || _link.hasMatch(raw.text);
    if (c < dropBelow && spammy) return out(Decision.drop, c);
    return out(Decision.review, c);
  }
}
