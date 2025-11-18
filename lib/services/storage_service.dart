// Storage service placeholder.
// Currently `SharedPreferences` is used directly across `main.dart` and
// `home_dashboard.dart`. A storage service unifies the key names and provides
// a single place for migrations when the transaction format changes.



import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/transaction_model.dart';
import '../utils/constants.dart';

class StorageService {
  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // Today's total
  static Future<double> getTodayTotal() async {
    final prefs = await _prefs;
    return prefs.getDouble(AppConstants.keyTodayTotal) ?? 0.0;
  }

  static Future<void> setTodayTotal(double total) async {
    final prefs = await _prefs;
    await prefs.setDouble(AppConstants.keyTodayTotal, total);
  }

  static Future<void> resetTodayTotal() async {
    await setTodayTotal(0.0);
  }

  // Transactions
  static Future<List<Map<String, dynamic>>> getTransactions() async {
    final prefs = await _prefs;
    final List<String>? jsonList = prefs.getStringList(AppConstants.keyTransactions);
    
    if (jsonList == null) return [];
    
    return jsonList
        .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
        .toList();
  }

  static Future<void> addTransaction(TransactionModel transaction) async {
    final prefs = await _prefs;
    final List<String> saved = prefs.getStringList(AppConstants.keyTransactions) ?? [];
    saved.add(jsonEncode(transaction.toMap()));
    await prefs.setStringList(AppConstants.keyTransactions, saved);
  }

  static Future<void> addTransactions(List<TransactionModel> transactions) async {
    final prefs = await _prefs;
    final List<String> saved = prefs.getStringList(AppConstants.keyTransactions) ?? [];
    
    for (final transaction in transactions) {
      saved.add(jsonEncode(transaction.toMap()));
    }
    
    await prefs.setStringList(AppConstants.keyTransactions, saved);
  }

  static Future<void> clearAllTransactions() async {
    final prefs = await _prefs;
    await prefs.remove(AppConstants.keyTransactions);
  }

  static Future<void> resetAllData() async {
    await clearAllTransactions();
    await resetTodayTotal();
  }

  // Calculate totals
  static Future<double> calculateTotal(DateTime since) async {
    final transactions = await getTransactions();
    
    double total = 0.0;
    for (final t in transactions) {
      try {
        if (DateTime.parse(t['time'].toString()).isAfter(since)) {
          total += (t['amount'] as num).toDouble();
        }
      } catch (e) {
        // Skip invalid transactions
      }
    }
    return total;
  }

  static Future<void> updateTodayTotalFromTransactions() async {
    final now = DateTime.now();
    final transactions = await getTransactions();
    
    double todayTotal = 0.0;
    for (final t in transactions) {
      try {
        final dt = DateTime.parse(t['time'].toString());
        if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
          todayTotal += (t['amount'] as num).toDouble();
        }
      } catch (e) {
        // Skip invalid transactions
      }
    }
    
    await setTodayTotal(todayTotal);
  }
}


// import 'package:shared_preferences/shared_preferences.dart';

// class StorageService {
//   static const _keyTodayTotal = 'todayTotal';
//   static const _keyTransactions = 'transactions';

//   Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

//   Future<double> getTodayTotal() async => (await _prefs()).getDouble(_keyTodayTotal) ?? 0.0;

//   Future<void> setTodayTotal(double total) async => (await _prefs()).setDouble(_keyTodayTotal, total);

//   Future<List<String>> getTransactions() async => (await _prefs()).getStringList(_keyTransactions) ?? [];

//   Future<void> setTransactions(List<String> transactions) async => (await _prefs()).setStringList(_keyTransactions, transactions);
// }
