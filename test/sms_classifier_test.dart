import 'package:expensetracker_reloaded/domain/sms/parsed_sms.dart';
import 'package:expensetracker_reloaded/domain/sms/sms_classifier.dart';
import 'package:expensetracker_reloaded/domain/sms/sms_template.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/sms_samples.dart';

void main() {
  const c = SmsClassifier();
  final at = DateTime(2026, 10, 12, 10);
  Classification run(
    String body, {
    String sender = 'VM-HDFCBK',
    RuleAction? Function(String)? rules,
  }) => c.classify(body: body, sender: sender, receivedAt: at, ruleFor: rules);

  group('template normalization', () {
    test('same template, different values -> same key', () {
      const a =
          'Rs.1,250.00 debited from a/c **1234 on 12-10-26 to VPA swiggy@icici (UPI Ref No 428512345678).';
      const b =
          'Rs.80 debited from a/c **9876 on 01-11-26 to VPA zomato@paytm (UPI Ref No 428500000001).';
      expect(normalizeTemplate(a), normalizeTemplate(b));
      expect(templateKey('VM-HDFCBK', a), templateKey('AD-HDFCBK', b));
    });
    test('masks amounts, accounts, dates, urls, digits', () {
      final t = normalizeTemplate(
        'INR 5,00,000 for A/c XX1234 on 05-Oct-2026 visit https://x.co/a code 99',
      );
      expect(t, '<amt> for a/c <acct> on <date> visit <url> code <n>');
    });
    test('different sender -> different key', () {
      expect(
        templateKey('VM-HDFCBK', 'Rs 5 debited'),
        isNot(templateKey('VM-ICICIB', 'Rs 5 debited')),
      );
    });
    test('sender normalization', () {
      expect(normalizeSender('vm-hdfcbk'), 'HDFCBK');
      expect(normalizeSender('AD-SBIUPI-S'), 'SBIUPI');
      expect(normalizeSender('+919876543210'), '+919876543210');
    });
  });

  group('loan / offer spam', () {
    const spam = [
      'Get instant loan of Rs 5,00,000! Pre-approved for you. Apply now https://bit.ly/abc',
      'Congratulations! You are eligible for a credit limit up to Rs 2,00,000. Avail now www.xyz.in',
      'Avail personal loan upto Rs 10 lakh at 10.5%. Click https://lnk.in/q',
      'Exclusive offer: get Rs 500 cashback on your first UPI payment. T&C apply',
      'Rs 3,00,000 loan approved instantly, claim within 24 hrs: http://cl.am/x',
    ];
    for (final s in spam) {
      test(
        s.substring(0, 30),
        () => expect(
          run(s, sender: 'VM-LOANAP').decision,
          isNot(Decision.accept),
        ),
      );
    }
    test('hard loan spam is dropped not queued', () {
      expect(run(spam[0], sender: 'VM-LOANAP').decision, Decision.drop);
      expect(run(spam[1], sender: 'VM-LOANAP').decision, Decision.drop);
    });
  });

  group('confident bank messages are accepted', () {
    for (final (sender, body, type, amount) in smsSamples.where(
      (s) => s.$3 != null,
    )) {
      test('$sender ${body.substring(0, 25)}', () {
        final r = run(body, sender: sender);
        expect(r.decision, isNot(Decision.drop));
        if (r.decision == Decision.accept) {
          expect(r.type!.name, type);
          expect(r.amountMinor, (amount! * 100).round());
        }
      });
    }
    test('typical UPI debit is accepted with high confidence', () {
      final r = run(
        'Rs.1,250.00 debited from a/c **1234 on 12-10-26 to VPA swiggy@icici (UPI Ref No 428512345678).',
      );
      expect(r.decision, Decision.accept);
      expect(r.confidence, greaterThanOrEqualTo(SmsClassifier.acceptAt));
    });
  });

  test('P1 non-transaction fixtures are never auto-accepted', () {
    for (final (sender, body, _, _) in smsSamples.where((s) => s.$3 == null)) {
      expect(
        run(body, sender: sender).decision,
        isNot(Decision.accept),
        reason: body,
      );
    }
  });

  test('uncertain message goes to review', () {
    final r = run(
      'Rs 499 towards your Netflix subscription',
      sender: 'VM-NFLX',
    );
    expect(r.decision, Decision.review);
  });

  test('OTP always dropped, even with a rule', () {
    expect(
      run(
        '123456 is your OTP for Rs 500',
        rules: (_) => RuleAction.debit,
      ).decision,
      Decision.drop,
    );
  });

  group('rule application', () {
    const body = 'Rs 499 towards your Netflix subscription';
    test('debit rule accepts as debit', () {
      final r = run(body, sender: 'VM-NFLX', rules: (_) => RuleAction.debit);
      expect(r.decision, Decision.accept);
      expect(r.type, TxnType.debit);
      expect(r.fromRule, isTrue);
    });
    test('credit rule flips type', () {
      final r = run(
        'Rs.100 debited from a/c XX12 Ref 123456789',
        rules: (_) => RuleAction.credit,
      );
      expect(r.type, TxnType.credit);
    });
    test('ignore rule drops', () {
      expect(
        run(body, sender: 'VM-NFLX', rules: (_) => RuleAction.ignore).decision,
        Decision.drop,
      );
    });
    test(
      'rule keyed by template: matches a new amount, not another sender',
      () {
        final learned = templateKey('VM-NFLX', body);
        RuleAction? rules(String k) => k == learned ? RuleAction.debit : null;
        expect(
          run(
            'Rs 649 towards your Netflix subscription',
            sender: 'AD-NFLX',
            rules: rules,
          ).fromRule,
          isTrue,
        );
        expect(run(body, sender: 'VM-OTHER', rules: rules).fromRule, isFalse);
      },
    );
  });
}
