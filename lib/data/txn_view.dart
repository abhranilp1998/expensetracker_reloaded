import 'db/app_database.dart';

/// Map shape the legacy list widgets render (amount in rupees, local ISO time).
Map<String, dynamic> txnToMap(TxnRow r) => {
  'id': r.id,
  'amount': r.amountMinor / 100,
  'type': r.type,
  'time': DateTime.fromMillisecondsSinceEpoch(r.occurredAt).toIso8601String(),
  'message': r.note ?? r.merchant ?? r.rawBody ?? '',
};

/// Oldest first, matching the legacy list order.
List<Map<String, dynamic>> txnMaps(List<TxnRow> newestFirst) =>
    newestFirst.reversed.map(txnToMap).toList();
