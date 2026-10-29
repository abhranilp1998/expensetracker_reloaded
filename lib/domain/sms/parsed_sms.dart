enum TxnType { debit, credit }

/// Result of parsing a bank/UPI SMS. Amounts are in minor units (paise).
class ParsedSms {
  final int amountMinor;
  final TxnType type;
  final String? merchant;
  final String? reference;
  final String sender;
  final DateTime receivedAt;
  final String dedupeHash;

  const ParsedSms({
    required this.amountMinor,
    required this.type,
    required this.sender,
    required this.receivedAt,
    required this.dedupeHash,
    this.merchant,
    this.reference,
  });

  double get amount => amountMinor / 100.0;
}
