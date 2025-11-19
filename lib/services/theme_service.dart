import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'app_theme_mode';
  static const String _accentColorKey = 'app_accent_color';

  static late SharedPreferences _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Get current theme mode
  static ThemeMode getCurrentTheme() {
    final savedTheme = _prefs.getString(_themeKey) ?? 'system';
    return _stringToThemeMode(savedTheme);
  }

  // Save theme preference
  static Future<void> setTheme(ThemeMode mode) async {
    await _prefs.setString(_themeKey, _themeModeToString(mode));
  }

  // Get current accent color
  static MaterialColor getCurrentAccentColor() {
    final colorName = _prefs.getString(_accentColorKey) ?? 'green';
    return _stringToColor(colorName);
  }

  // Save accent color preference
  static Future<void> setAccentColor(String colorName) async {
    await _prefs.setString(_accentColorKey, colorName);
  }

  // Convert string to ThemeMode
  static ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // Convert ThemeMode to string
  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  // Available accent colors
  static const Map<String, MaterialColor> availableColors = {
    'green': Colors.green,
    'blue': Colors.blue,
    'purple': Colors.purple,
    'teal': Colors.teal,
    'indigo': Colors.indigo,
    'orange': Colors.orange,
    'red': Colors.red,
    'pink': Colors.pink,
    'cyan': Colors.cyan,
  };

  // Convert string to MaterialColor
  static MaterialColor _stringToColor(String colorName) {
    return availableColors[colorName] ?? Colors.green;
  }

  // Get list of color names
  static List<String> getAvailableColorNames() {
    return availableColors.keys.toList();
  }
}

// Theme data generator
class AppThemeData {
  static ThemeData lightTheme(MaterialColor accentColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: accentColor,
      primaryColor: accentColor.shade600,
      scaffoldBackgroundColor: Colors.grey.shade50,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
        bodySmall: TextStyle(color: Colors.black87),
        headlineLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        titleSmall: TextStyle(color: Colors.black87),
        labelLarge: TextStyle(color: Colors.black87),
        labelMedium: TextStyle(color: Colors.black87),
        labelSmall: TextStyle(color: Colors.black87),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor.shade600,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor.shade600,
          side: BorderSide(color: accentColor.shade200),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor.shade600, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return accentColor.shade600;
          }
          return Colors.grey.shade400;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return accentColor.shade200;
          }
          return Colors.grey.shade300;
        }),
      ),
    );
  }

  static ThemeData darkTheme(MaterialColor accentColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: accentColor,
      primaryColor: accentColor.shade400,
      scaffoldBackgroundColor: const Color(0xFF121212),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFFFFFFF), fontSize: 16),
        bodyMedium: TextStyle(color: Color(0xFFE3E3E3), fontSize: 14),
        bodySmall: TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
        headlineLarge: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold, fontSize: 32),
        headlineMedium: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold, fontSize: 28),
        headlineSmall: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold, fontSize: 24),
        titleLarge: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold, fontSize: 20),
        titleMedium: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold, fontSize: 16),
        titleSmall: TextStyle(color: Color(0xFFE3E3E3), fontSize: 14),
        labelLarge: TextStyle(color: Color(0xFFFFFFFF), fontSize: 14),
        labelMedium: TextStyle(color: Color(0xFFE3E3E3), fontSize: 12),
        labelSmall: TextStyle(color: Color(0xFFB3B3B3), fontSize: 11),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: const Color(0xFFFFFFFF),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFFFFFF),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor.shade400,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor.shade400,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor.shade400,
          side: BorderSide(color: accentColor.shade700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor.shade400, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade800,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return accentColor.shade400;
          }
          return Colors.grey.shade600;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return accentColor.shade900;
          }
          return Colors.grey.shade700;
        }),
      ),
    );
  }
}

// Helper extension for easier theme usage
extension ThemeHelpers on BuildContext {
  /// Get proper background color based on theme
  Color getScaffoldBg() => Theme.of(this).scaffoldBackgroundColor;
  
  /// Get proper card color based on theme
  Color getCardColor() => Theme.of(this).cardColor;
  
  /// Get proper app bar color based on theme
  Color getAppBarBg() => Theme.of(this).appBarTheme.backgroundColor ?? Colors.white;
  
  /// Get primary color (accent)
  Color getPrimaryColor() => Theme.of(this).primaryColor;
  
  /// Check if dark mode
  bool isDarkMode() => Theme.of(this).brightness == Brightness.dark;
  
  /// Get text color based on theme
  Color getTextColor({bool isSecondary = false}) {
    if (isDarkMode()) {
      return isSecondary ? const Color(0xFFB3B3B3) : const Color(0xFFE3E3E3);
    } else {
      return isSecondary ? Colors.grey.shade600 : Colors.black87;
    }
  }
  
  /// Get a subtle color for backgrounds
  Color getSubtleBg() {
    if (isDarkMode()) {
      return const Color(0xFF1E1E1E);
    } else {
      return Colors.grey.shade100;
    }
  }
  
  /// Get border color
  Color getBorderColor() {
    if (isDarkMode()) {
      return Colors.grey.shade700;
    } else {
      return Colors.grey.shade300;
    }
  }
}

