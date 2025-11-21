import 'package:flutter/material.dart';

/// Application-wide constants for colors, sizing, animations, and configuration
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // ==================== COLORS ====================
  
  /// Primary color palette
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF388E3C);
  static const Color lightGreen = Color(0xFF66BB6A);
  static const Color accentGreen = Color(0xFF66BB6A);
  
  /// Secondary colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryPurple = Color(0xFF9C27B0);
  static const Color primaryOrange = Color(0xFFFF9800);
  static const Color primaryAmber = Color(0xFFFFC107);
  
  /// Status colors
  static const Color errorRed = Color(0xFFE53935);
  static const Color successGreen = Color(0xFF43A047);
  static const Color warningOrange = Color(0xFFFF6F00);
  static const Color infoBlue = Color(0xFF1976D2);
  
  /// Background colors
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundGrey = Color(0xFFF5F5F5);
  
  /// Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textWhite = Color(0xFFFFFFFF);
  
  /// Gradient colors
  static List<Color> get greenGradient => [
    const Color(0xFF66BB6A),
    const Color(0xFF388E3C),
  ];
  
  static List<Color> get blueGradient => [
    const Color(0xFF42A5F5),
    const Color(0xFF1976D2),
  ];
  
  static List<Color> get purpleGradient => [
    const Color(0xFFAB47BC),
    const Color(0xFF7B1FA2),
  ];
  
  static List<Color> get orangeGradient => [
    const Color(0xFFFF9800),
    const Color(0xFFE65100),
  ];

  // ==================== SIZING ====================
  
  /// Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusCircle = 999.0;
  
  /// Padding & Margins
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  /// Card properties
  static const double cardElevation = 4.0;
  static const double cardElevationHover = 8.0;
  static const double cardBorderRadius = 16.0;
  
  /// Icon sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;
  static const double iconSizeHuge = 64.0;
  
  /// Avatar sizes
  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeMedium = 48.0;
  static const double avatarSizeLarge = 80.0;
  static const double avatarSizeXLarge = 128.0;
  
  /// Button dimensions
  static const double buttonHeight = 48.0;
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightLarge = 56.0;

  // ==================== TYPOGRAPHY ====================
  
  /// Font sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeNormal = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 20.0;
  static const double fontSizeXXLarge = 24.0;
  static const double fontSizeTitle = 28.0;
  static const double fontSizeHeading = 32.0;
  static const double fontSizeDisplay = 42.0;
  static const double fontSizeHero = 56.0;
  
  /// Font weights
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtraBold = FontWeight.w800;

  // ==================== ANIMATIONS ====================
  
  /// Animation durations
  static const Duration animationFast = Duration(milliseconds: 100);
  static const Duration animationShort = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 400);
  static const Duration animationLong = Duration(milliseconds: 600);
  static const Duration animationSlow = Duration(milliseconds: 800);
  
  /// Animation curves
  static const Curve curveEaseIn = Curves.easeIn;
  static const Curve curveEaseOut = Curves.easeOut;
  static const Curve curveEaseInOut = Curves.easeInOut;
  static const Curve curveElastic = Curves.elasticOut;
  static const Curve curveBounce = Curves.bounceOut;

  // ==================== SHADOWS ====================
  
  /// Box shadows
  static List<BoxShadow> get shadowLight => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 15,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get shadowHeavy => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  static BoxShadow greenShadow({double opacity = 0.3}) => BoxShadow(
    color: primaryGreen.withOpacity(opacity),
    blurRadius: 20,
    spreadRadius: 5,
  );

  // ==================== NOTIFICATIONS ====================
  
  /// Notification configuration
  static const String notificationChannelId = 'expense_tracker';
  static const String notificationChannelName = 'Expense Notifications';
  static const String notificationChannelDescription = 
      'Notifications for expense tracking and daily summaries';
  
  /// Notification types
  static const int notificationIdExpense = 0;
  static const int notificationIdDailyReset = 1;
  static const int notificationIdCustom = 2;

  // ==================== STORAGE KEYS ====================
  
  /// SharedPreferences keys
  static const String keyTodayTotal = 'todayTotal';
  static const String keyTransactions = 'transactions';
  static const String keyLastResetDate = 'lastResetDate';
  static const String keyUserName = 'userName';
  static const String keyUserEmail = 'userEmail';
  static const String keyThemeMode = 'themeMode';
  static const String keyNotificationsEnabled = 'notificationsEnabled';
  static const String keySmsPermissionAsked = 'smsPermissionAsked';

  // ==================== APP CONFIG ====================
  
  /// App information
  static const String appName = 'Expense Tracker';
  static const String appVersion = '1.0.0';
  static const String appDescription = 
      'Track your expenses automatically from SMS messages';
  
  /// User defaults
  static const String defaultUserName = 'User';
  static const String defaultUserEmoji = '😁';
  
  /// Limits
  static const int maxTransactionsToShow = 5;
  static const int maxHistoryItems = 1000;
  static const double minExpenseAmount = 0.01;
  static const double maxExpenseAmount = 999999.99;

  // ==================== REGEX PATTERNS ====================
  
  /// SMS parsing pattern - matches currency symbols and amounts
  static const String smsAmountPattern = r'(?:rs\.?|inr|₹)\s*([0-9,]+\.?[0-9]*)';
  
  /// Transaction keywords - matches debit, credit, paid, charged, etc
  static const String transactionKeywordsPattern = 
      r'(?:debited|credited|paid|charged|spent|transferred|withdrawn|deposited|refunded)';
  
  /// Extended amount pattern with transaction context
  /// Matches: "debited for ₹500" or "paid INR 1000" or "charged Rs.200"
  static const String extendedSmsPattern = 
      r'(?:debited|credited|paid|charged|spent|transferred|withdrawn|deposited|refunded)(?:\s+(?:for|of|by))?\s*(?:rs\.?|inr|₹)?\s*([0-9,]+\.?[0-9]*)';
  
  /// Validation patterns
  static const String emailPattern = 
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}';



}