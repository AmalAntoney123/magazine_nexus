import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF55AD9B), // Teal
        secondary: const Color(0xFF95D2B3), // Mint green
        surface: const Color(0xFFF1F8E8), // Off white
        background: const Color(0xFFD8EFD3), // Light sage
        onPrimary: Colors.white, // White text on primary
        onSecondary: Colors.black87, // Dark text on secondary
        onSurface: Colors.black87, // Dark text on surface
        onBackground: Colors.black87, // Dark text on background
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: Color(0xFF55AD9B)),
        bodyLarge: TextStyle(color: Colors.black87),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF55AD9B),
        foregroundColor: Colors.white,
      ),
    );
  }
}
