// class TransactionModel {
//   final double amount;
//   final String time; // ISO 8601
//   final String message;

//   TransactionModel({required this.amount, required this.time, required this.message});

//   factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
//         amount: (json['amount'] as num).toDouble(),
//         time: json['time'] as String,
//         message: json['message'] as String,
//       );

//   Map<String, dynamic> toJson() => {
//         'amount': amount,
//         'time': time,
//         'message': message,
//       };
// }


class TransactionModel {
  final double amount;
  final DateTime time;
  final String message;

  TransactionModel({
    required this.amount,
    required this.time,
    required this.message,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      amount: (map['amount'] as num).toDouble(),
      time: DateTime.parse(map['time'].toString()),
      message: map['message'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'time': time.toIso8601String(),
      'message': message,
    };
  }

  static TransactionModel createManual(double amount, String message) {
    return TransactionModel(
      amount: amount,
      time: DateTime.now(),
      message: message,
    );
  }

  static List<TransactionModel> createSampleData() {
    final now = DateTime.now();
    return [
      TransactionModel(
        amount: 120.5,
        time: now,
        message: 'Demo: Coffee at Starbucks',
      ),
      TransactionModel(
        amount: 550.0,
        time: now.subtract(const Duration(hours: 1)),
        message: 'Demo: Lunch at restaurant',
      ),
      TransactionModel(
        amount: 79.0,
        time: now.subtract(const Duration(hours: 6)),
        message: 'Demo: Taxi ride',
      ),
      TransactionModel(
        amount: 320.0,
        time: now.subtract(const Duration(days: 1)),
        message: 'Demo: Groceries',
      ),
      TransactionModel(
        amount: 1500.0,
        time: now.subtract(const Duration(days: 7)),
        message: 'Demo: Monthly rent',
      ),
    ];
  }
}