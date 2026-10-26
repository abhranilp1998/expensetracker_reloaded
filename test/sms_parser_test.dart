import 'package:expensetracker_reloaded/domain/sms/parsed_sms.dart';
import 'package:expensetracker_reloaded/domain/sms/sms_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/sms_samples.dart';

void main() {
  const parser = SmsParser();
  final at = DateTime(2026, 10, 12, 10, 30);

  group('fixtures', () {
    for (final (sender, body, type, amount) in smsSamples) {
      test('$sender: ${body.length > 50 ? body.substring(0, 50) : body}', () {
        final r = parser.parse(body: body, sender: sender, receivedAt: at);
        if (type == null) {
          expect(r, isNull);
        } else {
          expect(r, isNotNull);
          expect(r!.type.name, type);
          expect(r.amountMinor, (amount! * 100).round());
        }
      });
    }
  });

  test('toMinor handles lakhs, decimals, garbage', () {
    expect(SmsParser.toMinor('1,23,456.78'), 12345678);
    expect(SmsParser.toMinor('5'), 500);
    expect(SmsParser.toMinor('10.5'), 1050);
    expect(
      SmsParser.toMinor('1,,2'),
      100 * 12,
    ); // regex never yields this; tolerant
    expect(SmsParser.toMinor('abc'), isNull);
  });

  test('dedupe: same SMS -> same hash, different ref -> different hash', () {
    const b = 'Rs.100 debited from a/c XX1 UPI Ref No 428500000001';
    final a1 = parser.parse(body: b, sender: 'VM-HDFCBK', receivedAt: at)!;
    final a2 = parser.parse(
      body: b,
      sender: 'vm-hdfcbk',
      receivedAt: at.add(const Duration(minutes: 5)),
    )!;
    expect(a1.dedupeHash, a2.dedupeHash);
    final c = parser.parse(
      body: b.replaceAll('0001', '0002'),
      sender: 'VM-HDFCBK',
      receivedAt: at,
    )!;
    expect(c.dedupeHash, isNot(a1.dedupeHash));
  });

  test('dedupe without ref uses minute bucket', () {
    const b = 'Rs 50 spent at CAFE on card XX1';
    final x = parser.parse(body: b, sender: 'S', receivedAt: at)!;
    final y = parser.parse(
      body: b,
      sender: 'S',
      receivedAt: at.add(const Duration(seconds: 20)),
    )!;
    final z = parser.parse(
      body: b,
      sender: 'S',
      receivedAt: at.add(const Duration(minutes: 3)),
    )!;
    expect(x.dedupeHash, y.dedupeHash);
    expect(x.dedupeHash, isNot(z.dedupeHash));
    expect(x.type, TxnType.debit);
  });

  test('never throws on arbitrary input', () {
    for (final s in ['₹', 'rs', '₹₹₹ 9' * 100, '\u0000debited Rs 1']) {
      expect(
        () => parser.parse(body: s, sender: '', receivedAt: at),
        returnsNormally,
      );
    }
  });
}
