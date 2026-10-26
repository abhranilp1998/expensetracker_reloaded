/// (sender, body, expected type 'debit'|'credit'|null, expected amount rupees)
const smsSamples = <(String, String, String?, double?)>[
  // Debits
  (
    'VM-HDFCBK',
    'Rs.1,250.00 debited from a/c **1234 on 12-10-26 to VPA swiggy@icici (UPI Ref No 428512345678). Not you? Call 18002586161',
    'debit',
    1250.00,
  ),
  (
    'AD-SBIUPI',
    'Dear UPI user A/C X5678 debited by 450.0 on date 12Oct26 trf to ZOMATO Refno 428599887766. If not u? call 1800111109. -SBI',
    'debit',
    450.0,
  ),
  (
    'JD-ICICIB',
    'ICICI Bank Acct XX901 debited for Rs 2,999.00 on 10-Oct-26; AMAZON credited. UPI:428511112222. Call 18002662 for dispute.',
    'debit',
    2999.00,
  ),
  (
    'AX-AXISBK',
    'Spent INR 799 on Axis Bank Card no. XX4321 at NETFLIX on 11-10-26. Avl Lmt INR 45,201.00',
    'debit',
    799,
  ),
  (
    'VK-KOTAKB',
    'Sent Rs.120.50 from Kotak Bank AC X1111 to chai@ybl on 12-10-26. UPI Ref 428533334444. Not you, https://kotak.com/fraud',
    'debit',
    120.50,
  ),
  (
    'BZ-PHONPE',
    'Paid ₹349 to Dominos Pizza from A/c XX22. UPI Ref: 428544445555',
    'debit',
    349,
  ),
  (
    'VM-PAYTMB',
    'Rs 60 paid to Metro Card Recharge from Paytm Wallet. Txn ID 2026101212345',
    'debit',
    60,
  ),
  (
    'AD-HDFCBK',
    'Rs.2000 withdrawn from HDFC Bank Card x1234 at ATM MG ROAD on 2026-10-12. Avl bal Rs.10,500.00',
    'debit',
    2000,
  ),
  (
    'AD-SBIINB',
    'Your a/c no. XXXXXXXX1234 is debited for Rs.15000.00 on 01-10-26 and credited to a/c no. XXXXXXXX9999 (UPI Ref no 428566667777)',
    'debit',
    15000,
  ),
  (
    'VM-ICICIB',
    'INR 1,23,456.78 spent on ICICI Bank Card XX5555 on 05-Oct-26 at APPLE INDIA. Avl Limit: INR 2,00,000.00',
    'debit',
    123456.78,
  ),
  (
    'CP-IDFCFB',
    'Purchase of Rs. 89.00 at UBER INDIA using IDFC FIRST Bank Credit Card XX12 on 12/10/26',
    'debit',
    89,
  ),
  (
    'AX-HDFCBK',
    'Rs 5 debited from A/c 1234 on 12-OCT-26. Ref 428577778888',
    'debit',
    5,
  ),
  (
    'VM-YESBNK',
    'INR 300.00 deducted from your Yes Bank A/c XX45 towards FASTAG RECHARGE. Ref no 0098765432',
    'debit',
    300,
  ),
  (
    'BP-BOIIND',
    'Rs.75 debited A/c XX88 for UPI to grocer@okaxis Ref 428588889999. Bal Rs 1,000.00',
    'debit',
    75,
  ),
  // Credits
  (
    'VM-HDFCBK',
    'Rs.50,000.00 credited to a/c **1234 on 01-10-26 by a/c linked to VPA employer@hdfc (UPI Ref No 428500001111).',
    'credit',
    50000,
  ),
  (
    'AD-SBIINB',
    'Dear Customer, INR 1,500 credited to your A/c XX5678 on 10-10-26 by NEFT from RAHUL. Avl Bal INR 25,000.00',
    'credit',
    1500,
  ),
  (
    'JD-ICICIB',
    'Refund of Rs 2,999.00 for AMAZON credited to ICICI Bank Card XX901 on 12-Oct-26.',
    'credit',
    2999,
  ),
  (
    'BZ-PHONPE',
    'Received ₹200 from Amit in your A/c XX22. UPI Ref: 428511110000',
    'credit',
    200,
  ),
  (
    'VK-KOTAKB',
    'Rs 10 cashback of reward credited to Kotak A/c X1111',
    'credit',
    10,
  ),
  (
    'AX-AXISBK',
    'INR 3,200.00 deposited in A/c no. XX4321 on 11-10-26 by cash. Avl Bal INR 9,800.00',
    'credit',
    3200,
  ),
  // Ignored: OTP
  (
    'VM-HDFCBK',
    '123456 is your OTP for txn of Rs.1,250.00 at AMAZON. Do not share it with anyone.',
    null,
    null,
  ),
  (
    'AD-ICICIB',
    'Your one time password for payment of INR 499 is 998877. Valid 5 min.',
    null,
    null,
  ),
  (
    'JD-SBIUPI',
    'Use verification code 4455 to authorise debit of Rs 300 from A/c XX12',
    null,
    null,
  ),
  // Ignored: promos
  (
    'VM-FLPKRT',
    'Big Billion Days! Flat Rs.500 OFF on orders above Rs 2999. Shop now: fkrt.it/x',
    null,
    null,
  ),
  (
    'AD-HDFCBK',
    'Congratulations! You are pre-approved for a Personal Loan of Rs 5,00,000. Apply now',
    null,
    null,
  ),
  (
    'BZ-SWIGGY',
    'Get cashback upto Rs 100 on your next order. Limited period offer!',
    null,
    null,
  ),
  (
    'VM-AIRTEL',
    'Win Rs 10,000 every day! Recharge with Rs 299 plan. Click here',
    null,
    null,
  ),
  // Ignored: balance only / info
  (
    'AD-SBIINB',
    'Avl Bal in A/c XX5678 as on 12-10-26 is INR 25,000.00',
    null,
    null,
  ),
  (
    'VM-HDFCBK',
    'Your A/c XX1234 balance is Rs 10,000.00 as of today.',
    null,
    null,
  ),
  // Ignored: reminders
  (
    'AX-AXISBK',
    'Payment of Rs 12,345 for Axis Credit Card XX4321 is due on 20-10-26. Minimum due Rs 620.',
    null,
    null,
  ),
  (
    'VM-BAJAJF',
    'EMI of Rs 4,500 will be debited from your account on 05-11-26.',
    null,
    null,
  ),
  (
    'BZ-PHONPE',
    'Rahul has requested money of Rs 500 on PhonePe. Collect request expires soon',
    null,
    null,
  ),
  // Ignored: failed
  (
    'VM-HDFCBK',
    'Txn of Rs.999.00 on HDFC Card x1234 at MYNTRA failed due to incorrect PIN.',
    null,
    null,
  ),
  (
    'JD-ICICIB',
    'Your UPI payment of Rs 150 to cafe@ybl was declined. Insufficient balance.',
    null,
    null,
  ),
  // Malformed / no currency
  ('VM-TEST', 'Rs.1,,2 debited from a/c', null, null),
  ('VM-TEST', 'debited from a/c without amount', null, null),
  ('VM-TEST', '', null, null),
  ('VM-TEST', 'Paid 500 to friend', null, null),
  ('VM-TEST', 'Rs. debited', null, null),
  ('VM-TEST', 'Rs 0.00 debited from a/c XX12', null, null),
];
