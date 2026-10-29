import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expensetracker_reloaded/data/txn_view.dart';
import 'package:expensetracker_reloaded/services/theme_service.dart';

void main() {
  final swiggy = {
    'amount': 349.0,
    'merchant': 'Swiggy',
    'note': 'dinner',
    'sender': 'AX-HDFCBK',
    'message': 'dinner',
  };

  group('Activity search', () {
    test('matches merchant, note, sender case-insensitively', () {
      expect(txnMatchesSearch(swiggy, 'swig'), isTrue);
      expect(txnMatchesSearch(swiggy, 'DINNER'), isTrue);
      expect(txnMatchesSearch(swiggy, 'hdfc'), isTrue);
    });
    test('matches amount', () {
      expect(txnMatchesSearch(swiggy, '349'), isTrue);
      expect(txnMatchesSearch(swiggy, '349.00'), isTrue);
    });
    test('rejects non-matches; empty query matches all', () {
      expect(txnMatchesSearch(swiggy, 'zomato'), isFalse);
      expect(txnMatchesSearch(swiggy, '999'), isFalse);
      expect(txnMatchesSearch(swiggy, '  '), isTrue);
    });
  });

  group('Accent drives ColorScheme', () {
    test('light and dark primary follow the accent', () {
      for (final c in ThemeService.availableColors.values) {
        expect(AppThemeData.lightTheme(c).colorScheme.primary, c.shade600);
        expect(AppThemeData.darkTheme(c).colorScheme.primary, c.shade400);
      }
    });
    test('changing accent changes colorScheme.primary', () {
      final a = AppThemeData.lightTheme(Colors.green).colorScheme.primary;
      final b = AppThemeData.lightTheme(Colors.indigo).colorScheme.primary;
      expect(a, isNot(b));
    });
  });
}
