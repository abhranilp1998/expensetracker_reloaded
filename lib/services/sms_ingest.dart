import '../data/repositories/transaction_repository.dart';
import '../domain/sms/parsed_sms.dart';
import '../domain/sms/sms_classifier.dart';

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
  if (c.decision == Decision.drop || c.amountMinor == null) return null;
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
  return inserted
      ? IngestResult(c.decision, c.amountMinor!, type, c.merchant, c.dedupeHash)
      : null;
}

String describe(IngestResult p) {
  final amt = '₹${p.amount.toStringAsFixed(2)}';
  if (p.decision == Decision.review) return '$amt — tap to review';
  final who = p.merchant == null ? '' : ' · ${p.merchant}';
  return p.type == TxnType.debit ? '$amt spent$who' : '$amt received$who';
}
