import '../data/repositories/transaction_repository.dart';
import '../domain/sms/parsed_sms.dart';
import '../domain/sms/sms_classifier.dart';
import 'package:expensetracker_reloaded/utils/money.dart';

/// Counts returned by an SMS import/ingest run (inserted, duplicate, review, ignored).
class IngestResult {
  final Decision decision;
  final int amountMinor;
  final TxnType type;
  final String? merchant;
  final String dedupeHash;
  const IngestResult(
    this.decision,
    this.amountMinor,
    this.type,
    this.merchant,
    this.dedupeHash,
  );
  double get amount => amountMinor / 100;
}

/// What happened to one SMS during ingest (used for import summaries).
enum IngestStatus {
  /// Stored as a confirmed transaction.
  added,

  /// Stored in the Review queue (uncertain match, not in totals).
  review,

  /// Already stored earlier (same SMS or same bank reference).
  duplicate,

  /// Not a transaction (OTP, promo, failed, ignored by a rule...).
  dropped,
}

/// Classify one SMS and store it: accepted -> confirmed row, uncertain ->
/// 'review' row (excluded from totals), spam -> nothing.
/// Returns null when nothing new was stored (dropped or duplicate).
Future<IngestResult?> ingestSms(
  TransactionRepository repo, {
  required String body,
  required String sender,
  required DateTime receivedAt,
  String source = 'sms',
  SmsClassifier classifier = const SmsClassifier(),
  Map<String, String>? rules,
}) async => (await ingestSmsWithStatus(
  repo,
  body: body,
  sender: sender,
  receivedAt: receivedAt,
  source: source,
  classifier: classifier,
  rules: rules,
)).result;

/// Same as [ingestSms] but also says why nothing was stored.
Future<({IngestStatus status, IngestResult? result})> ingestSmsWithStatus(
  TransactionRepository repo, {
  required String body,
  required String sender,
  required DateTime receivedAt,
  String source = 'sms',
  SmsClassifier classifier = const SmsClassifier(),
  Map<String, String>? rules,
}) async {
  final learned = rules ?? await repo.activeRules();
  final c = classifier.classify(
    body: body,
    sender: sender,
    receivedAt: receivedAt,
    ruleFor: (k) => switch (learned[k]) {
      'debit' => RuleAction.debit,
      'credit' => RuleAction.credit,
      'ignore' => RuleAction.ignore,
      _ => null,
    },
  );
  if (c.decision == Decision.drop || c.amountMinor == null) {
    return (status: IngestStatus.dropped, result: null);
  }
  final type = c.type ?? TxnType.debit;
  final inserted = await repo.insert(
    NewTxn(
      amountMinor: c.amountMinor!,
      type: type.name,
      source: source,
      occurredAt: receivedAt,
      dedupeHash: c.dedupeHash,
      rawBody: body,
      sender: sender,
      merchant: c.merchant,
      status: c.decision == Decision.accept ? 'confirmed' : 'review',
      templateKey: c.templateKey,
      confidence: c.confidence,
    ),
  );
  if (!inserted) return (status: IngestStatus.duplicate, result: null);
  return (
    status: c.decision == Decision.accept
        ? IngestStatus.added
        : IngestStatus.review,
    result: IngestResult(
      c.decision,
      c.amountMinor!,
      type,
      c.merchant,
      c.dedupeHash,
    ),
  );
}

String describe(IngestResult p) {
  final amt = Money.minor(p.amountMinor);
  if (p.decision == Decision.review) return '$amt — tap to review';
  final who = p.merchant == null ? '' : ' · ${p.merchant}';
  return p.type == TxnType.debit ? '$amt spent$who' : '$amt received$who';
}
