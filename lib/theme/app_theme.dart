import 'package:flutter/material.dart';

class WhatsAppTheme {
  // WhatsApp Signature Colors
  static const Color primaryTeal = Color(0xFF128C7E);
  static const Color darkTeal = Color(0xFF075E54);
  static const Color accentGreen = Color(0xFF00A884);
  static const Color lightGreen = Color(0xFF25D366);
  static const Color outgoingBubble = Color(0xFF005C4B);
  static const Color incomingBubble = Color(0xFF202C33);
  static const Color incomingBubbleLight = Color(0xFFFFFFFF);
  static const Color chatBgDark = Color(0xFF0B141A);
  static const Color chatBgLight = Color(0xFFEFEAE2);
  static const Color darkBackground = Color(0xFF121B22);
  static const Color darkSurface = Color(0xFF1F2C34);
  static const Color darkTextPrimary = Color(0xFFE9EDEF);
  static const Color darkTextSecondary = Color(0xFF8696A0);
  static const Color badgeGreen = Color(0xFF00A884);
  static const Color blueCheck = Color(0xFF53BDEB);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryTeal,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: accentGreen,
        secondary: accentGreen,
        surface: darkSurface,
        onSurface: darkTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 1,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: darkTextSecondary),
      ),
      dividerColor: Color(0xFF222D34),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryTeal,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: primaryTeal,
        secondary: accentGreen,
        surface: Colors.white,
        onSurface: Color(0xFF111B21),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryTeal,
        elevation: 1,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      dividerColor: Color(0xFFE9EDEF),
    );
  }
}
