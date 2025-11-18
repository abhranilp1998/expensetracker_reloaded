# Quick Reference: Global Components

## Routes

```dart
import 'package:expensetracker_reloaded/routes/app_routes.dart';

// Route constants
AppRoutes.welcome     // '/'
AppRoutes.home        // '/home'
AppRoutes.settings    // '/settings'
AppRoutes.history     // '/history'
AppRoutes.demo        // '/demo'
AppRoutes.profile     // '/profile'

// Navigation
Navigator.of(context).pushNamed(AppRoutes.home);
Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);

// Create route manually
createRoute(const MyPage())
```

## Services

### Storage Service
```dart
import 'package:expensetracker_reloaded/services/storage_service.dart';

// Today's total
final total = await StorageService.getTodayTotal();
await StorageService.setTodayTotal(500.0);
await StorageService.resetTodayTotal();

// Transactions
final txs = await StorageService.getTransactions();
await StorageService.addTransaction(transaction);
await StorageService.addTransactions([tx1, tx2]);
await StorageService.clearAllTransactions();

// Calculate
final sum = await StorageService.calculateTotal(DateTime(2025, 11, 1));
await StorageService.updateTodayTotalFromTransactions();

// Reset
await StorageService.resetAllData();
```

### SMS Service
```dart
import 'package:expensetracker_reloaded/services/sms_service.dart';

// Check permissions
final granted = await SmsService.requestPermission();
final hasAccess = await SmsService.checkPermission();

// Listen for SMS (foreground)
SmsService.listenForSms((transaction) {
  print('Expense: ${transaction.amount}');
});

// Parse message manually
final tx = SmsService.parseManualMessage('Rs 500 spent');
```

### Notification Service
```dart
import 'package:expensetracker_reloaded/services/notification_service.dart';

// Show notification
await NotificationService.showNotification(
  title: 'Expense Found',
  body: '₹500 spent',
);
```

## Models

```dart
import 'package:expensetracker_reloaded/models/transaction_model.dart';

// Create transaction
final tx = TransactionModel(
  amount: 500.0,
  time: DateTime.now(),
  message: 'Coffee at Starbucks',
);

// From map (storage)
final tx2 = TransactionModel.fromMap({
  'amount': 500.0,
  'time': '2025-11-18T10:30:00.000Z',
  'message': 'Lunch',
});

// To map (for storage)
final map = tx.toMap();

// Helpers
final manual = TransactionModel.createManual(100.0, 'Manual entry');
final samples = TransactionModel.createSampleData();
```

## Constants

```dart
import 'package:expensetracker_reloaded/utils/constants.dart';

// Colors
AppConstants.primaryGreen
AppConstants.errorRed
AppConstants.successGreen
AppConstants.greenGradient

// Sizes
AppConstants.paddingMedium
AppConstants.radiusLarge
AppConstants.buttonHeight
AppConstants.iconSizeLarge

// Text
AppConstants.fontSizeLarge
AppConstants.fontWeightBold

// Animations
AppConstants.animationMedium  // Duration(milliseconds: 400)
AppConstants.curveEaseInOut

// Shadows
AppConstants.shadowMedium

// Storage Keys
AppConstants.keyTodayTotal
AppConstants.keyTransactions
AppConstants.notificationChannelId

// App Info
AppConstants.appName
AppConstants.appVersion
AppConstants.smsAmountPattern
```

## Utility Functions

```dart
import 'package:expensetracker_reloaded/utils/date_helpers.dart';

// Format dates, get day/month, etc.

import 'package:expensetracker_reloaded/utils/animations.dart';

// Animation helpers
```

## Widgets

All widgets are in `lib/widgets/` and can be imported:

```dart
import 'package:expensetracker_reloaded/widgets/action_card.dart';
import 'package:expensetracker_reloaded/widgets/transaction_tile.dart';
import 'package:expensetracker_reloaded/widgets/app_drawer.dart';
// ... etc
```

## Screens

All screens are in `lib/screens/`:

```dart
import 'package:expensetracker_reloaded/screens/home_dashboard.dart';
import 'package:expensetracker_reloaded/screens/welcome_screen.dart';
import 'package:expensetracker_reloaded/screens/history_page.dart';
import 'package:expensetracker_reloaded/screens/settings_page.dart';
import 'package:expensetracker_reloaded/screens/profile_page.dart';
import 'package:expensetracker_reloaded/screens/demo_page.dart';
```

## Common Patterns

### Add an expense programmatically
```dart
final tx = TransactionModel.createManual(
  499.99,
  'Store purchase',
);
await StorageService.addTransaction(tx);
final newTotal = await StorageService.getTodayTotal();
```

### Get today's transactions
```dart
final now = DateTime.now();
final allTxs = await StorageService.getTransactions();
final todayTxs = allTxs.where((t) {
  final dt = DateTime.parse(t['time']);
  return dt.year == now.year && 
         dt.month == now.month && 
         dt.day == now.day;
}).toList();
```

### Navigate with custom route
```dart
Navigator.of(context).push(
  createRoute(const MyPage()),
);
```

### Check SMS permission before listening
```dart
if (await SmsService.checkPermission()) {
  SmsService.listenForSms((tx) {
    // Handle transaction
  });
} else {
  final granted = await SmsService.requestPermission();
  if (granted) {
    // Listen
  }
}
```

---

**All components are now globally accessible from anywhere in the app!** ✅
