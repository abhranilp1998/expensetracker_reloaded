import '../data/repositories/transaction_repository.dart';
import '../domain/sms/parsed_sms.dart';
import '../domain/sms/sms_parser.dart';

/// Parse one SMS and store it if it is a new transaction.
/// Returns the parsed result only when a new row was inserted.
Future<ParsedSms?> ingestSms(
  TransactionRepository repo, {
  required String body,
  required String sender,
  required DateTime receivedAt,
  String source = 'sms',
  SmsParser parser = const SmsParser(),
}) async {
  final p = parser.parse(body: body, sender: sender, receivedAt: receivedAt);
  if (p == null) return null;
  final inserted = await repo.insert(
    NewTxn(
      amountMinor: p.amountMinor,
      type: p.type.name,
      source: source,
      occurredAt: p.receivedAt,
      dedupeHash: p.dedupeHash,
      rawBody: body,
      sender: sender,
      merchant: p.merchant,
    ),
  );
  return inserted ? p : null;
}

String describe(ParsedSms p) {
  final amt = '₹${p.amount.toStringAsFixed(2)}';
  final who = p.merchant == null ? '' : ' · ${p.merchant}';
  return p.type == TxnType.debit ? '$amt spent$who' : '$amt received$who';
}
