import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// One place for money: parsing user input and formatting amounts.
///
/// Amounts are stored as integer minor units (paise/cents) in the DB, so
/// every total is an exact integer sum. Display always uses 2 decimals, so a
/// total on screen always equals the sum of the rows shown under it.
class Money {
  Money._();

  /// Currency codes offered in onboarding/Profile, with their symbols.
  static const symbols = <String, String>{
    'INR': '₹',
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
    'AED': 'AED ',
  };

  /// Active currency code. Set by `CurrencyController` (providers.dart) at
  /// startup and whenever the user changes it in Profile.
  static String code = 'INR';

  static String symbolFor(String c) => symbols[c] ?? '$c ';

  static String get symbol => symbolFor(code);

  static final _number = NumberFormat('#,##0.00', 'en_US');

  /// Formats minor units, e.g. 112050 -> "₹1,120.50".
  /// [signed] adds "+" for positive and "-" for negative values; otherwise a
  /// negative value still gets a leading "-" (never silently dropped).
  static String minor(int minorUnits, {bool signed = false, String? currency}) {
    final sym = symbolFor(currency ?? code);
    final body = _number.format(minorUnits.abs() / 100);
    final sign = minorUnits < 0 ? '-' : (signed && minorUnits > 0 ? '+' : '');
    return '$sign$sym$body';
  }

  /// Same as [minor] for a major-unit double (rounded to the nearest minor).
  static String major(num amount, {bool signed = false, String? currency}) =>
      minor((amount * 100).round(), signed: signed, currency: currency);

  /// Converts a major-unit amount to minor units.
  static int toMinor(num amount) => (amount * 100).round();
}

/// Result of [parseMoneyInput]: either [minor] or an [error] message.
class MoneyParse {
  const MoneyParse.ok(int this.minor) : error = null;
  const MoneyParse.fail(String this.error) : minor = null;
  final int? minor;
  final String? error;
  bool get isValid => minor != null;
}

/// Plain positive amount: digits, optional "." and at most 2 decimals.
/// Commas are accepted as thousands separators and ignored.
/// Rejects exponent ("1e3"), signs, spaces inside, and more than 2 decimals.
final _moneyPattern = RegExp(r'^\d+(\.\d{0,2})?$|^\.\d{1,2}$');

/// Upper bound to keep paise in a safe int range and catch typos.
const maxMoneyMinor = 100000000000; // 1,000,000,000.00

MoneyParse parseMoneyInput(String input) {
  final s = input.replaceAll(',', '').trim();
  if (s.isEmpty) return const MoneyParse.fail('Enter an amount');
  if (!_moneyPattern.hasMatch(s)) {
    return const MoneyParse.fail(
      'Use digits only, with up to 2 decimals (e.g. 120.50)',
    );
  }
  final parts = s.split('.');
  final whole = parts[0].isEmpty ? 0 : int.parse(parts[0]);
  final frac = parts.length > 1 ? parts[1].padRight(2, '0') : '00';
  if (parts[0].length > 10) {
    return const MoneyParse.fail('Amount is too large');
  }
  final minor = whole * 100 + int.parse(frac);
  if (minor <= 0)
    return const MoneyParse.fail('Enter an amount greater than 0');
  if (minor > maxMoneyMinor)
    return const MoneyParse.fail('Amount is too large');
  return MoneyParse.ok(minor);
}

/// Keyboard-level guard for money fields: only digits, commas and a single
/// ".", with at most 2 digits after it. Blocks "e", "-", "+" and spaces.
class MoneyInputFormatter extends TextInputFormatter {
  static final _allowed = RegExp(r'^[\d,]*(\.\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => _allowed.hasMatch(newValue.text) ? newValue : oldValue;
}

/// "1 transaction", "2 transactions".
String plural(int n, String singular, [String? pluralForm]) =>
    '$n ${n == 1 ? singular : (pluralForm ?? '${singular}s')}';

/// Shown under every currency picker: switching never converts amounts.
const currencySymbolNote =
    'Changes the symbol only; amounts are not converted.';
