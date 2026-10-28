import 'db/app_database.dart';

/// Map shape the legacy list widgets render (amount in rupees, local ISO time).
Map<String, dynamic> txnToMap(TxnRow r) => {
  'id': r.id,
  'amount': r.amountMinor / 100,
  'type': r.type,
  'time': DateTime.fromMillisecondsSinceEpoch(r.occurredAt).toIso8601String(),
  'message': r.note ?? r.merchant ?? r.rawBody ?? '',
  'merchant': r.merchant ?? '',
  'note': r.note ?? '',
  'sender': r.sender ?? '',
};

/// Case-insensitive match on merchant, note, sender, message or amount.
bool txnMatchesSearch(Map<String, dynamic> t, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  final amount = t['amount'];
  final amountStrs = <String>[
    amount.toString(),
    if (amount is num) amount.toStringAsFixed(2),
    if (amount is num && amount == amount.roundToDouble())
      amount.toInt().toString(),
  ];
  final fields = [
    t['merchant'],
    t['note'],
    t['sender'],
    t['message'],
  ].map((e) => (e ?? '').toString().toLowerCase());
  return fields.any((f) => f.contains(q)) ||
      amountStrs.any((a) => a.contains(q));
}

/// Oldest first, matching the legacy list order.
List<Map<String, dynamic>> txnMaps(List<TxnRow> newestFirst) =>
    newestFirst.reversed.map(txnToMap).toList();
