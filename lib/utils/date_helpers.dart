import 'package:intl/intl.dart';

String formatCurrency(double value) {
  final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  return formatter.format(value);
}

String isoNow() => DateTime.now().toIso8601String();


// import 'package:intl/intl.dart';

class DateHelpers {
  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy hh:mm a').format(date);
  }

  static String formatDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatDateHeader(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }

  static Map<String, List<Map<String, dynamic>>> groupTransactionsByDate(
    List<Map<String, dynamic>> transactions,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    
    for (final t in transactions.reversed) {
      final date = DateTime.parse(t['time'].toString());
      final key = formatDateKey(date);
      
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(t);
    }
    
    return grouped;
  }
}