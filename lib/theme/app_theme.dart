// theme/app_theme.dart - Final fixes for Flutter 3 compatibility
import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF22C55E); // Green 600
  static const Color primaryLightColor = Color(0xFFDCFCE7); // Green 100
  static const Color primaryDarkColor = Color(0xFF15803D); // Green 700
  static const Color accentColor = Color(0xFF0EA5E9); // Sky 500
  static const Color textDarkColor = Color(0xFF1F2937); // Gray 800
  static const Color textLightColor = Color(0xFF6B7280); // Gray 500
  static const Color backgroundLight = Color(0xFFF9FAFB); // Gray 50
  static const Color errorColor = Color(0xFFEF4444); // Red 500
  static const Color cardColor = Colors.white;
  static const Color dividerColor = Color(0xFFE5E7EB); // Gray 200

  // Text Styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textDarkColor,
    height: 1.3,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textDarkColor,
    height: 1.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textDarkColor,
    height: 1.3,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textDarkColor,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    color: textLightColor,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: textLightColor,
    height: 1.3,
  );

  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    elevation: 1,
  );

  static ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    backgroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    side: BorderSide(color: primaryColor, width: 1.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryColor,
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  );

  // Card Styles
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        offset: Offset(0, 2),
        blurRadius: 8,
        spreadRadius: 0,
      ),
    ],
  );

  // Input Decoration - Converted to Theme
  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    hintStyle: bodySmall.copyWith(color: textLightColor.withOpacity(0.7)),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: dividerColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: dividerColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: errorColor, width: 1),
    ),
  );

  // Dropdown Decoration
  static BoxDecoration dropdownDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: dividerColor),
  );

  // Chip Style
  static ChipThemeData chipTheme = ChipThemeData(
    backgroundColor: primaryLightColor,
    disabledColor: Colors.grey.shade200,
    selectedColor: primaryColor,
    secondarySelectedColor: primaryDarkColor,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    labelStyle: caption.copyWith(color: primaryDarkColor, fontWeight: FontWeight.w600),
    secondaryLabelStyle: caption.copyWith(color: Colors.white),
    brightness: Brightness.light,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  );

  // Helper for text formatting
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Light Theme - Updated for Flutter 3
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    primaryColorLight: primaryLightColor,
    primaryColorDark: primaryDarkColor,
    canvasColor: backgroundLight,
    scaffoldBackgroundColor: backgroundLight,
    cardColor: cardColor,
    dividerColor: dividerColor,
    fontFamily: 'Poppins',
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: secondaryButtonStyle),
    textButtonTheme: TextButtonThemeData(style: textButtonStyle),
    inputDecorationTheme: inputDecorationTheme,
    chipTheme: chipTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: textDarkColor),
      titleTextStyle: heading3.copyWith(fontSize: 20),
    ),
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      primaryContainer: primaryDarkColor, // Replaces primaryVariant
      secondary: accentColor,
      secondaryContainer: accentColor.withOpacity(0.8), // Darker variant for secondary
      surface: cardColor,
      background: backgroundLight,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textDarkColor,
      onBackground: textDarkColor,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
  );

  // Dark Theme - Updated for Flutter 3
  static ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      primaryContainer: primaryDarkColor,
      secondaryContainer: accentColor.withOpacity(0.8),
    ),
  );
}