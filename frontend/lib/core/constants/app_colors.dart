import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF3498DB); // Blue
  static const Color primaryDark = Color(0xFF2980B9);
  static const Color primaryLight = Color(0xFF5DADE2);

  // Success/Income
  static const Color success = Color(0xFF27AE60); // Green
  static const Color income = Color(0xFF27AE60);

  // Danger/Expense
  static const Color danger = Color(0xFFE74C3C); // Red
  static const Color expense = Color(0xFFE74C3C);

  // Warning
  static const Color warning = Color(0xFFF39C12); // Orange

  // Neutral Colors
  static const Color dark = Color(0xFF2C3E50);
  static const Color light = Color(0xFFECF0F1);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Gray Scale
  static const Color gray900 = Color(0xFF212529);
  static const Color gray800 = Color(0xFF343A40);
  static const Color gray700 = Color(0xFF495057);
  static const Color gray600 = Color(0xFF6C757D);
  static const Color gray500 = Color(0xFFADB5BD);
  static const Color gray400 = Color(0xFFCED4DA);
  static const Color gray300 = Color(0xFFDEE2E6);
  static const Color gray200 = Color(0xFFE9ECEF);
  static const Color gray100 = Color(0xFFF8F9FA);

  // Background
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textDisabled = Color(0xFFADB5BD);

  // Border
  static const Color border = Color(0xFFDEE2E6);
  static const Color divider = Color(0xFFE9ECEF);

  // Transparent
  static const Color transparent = Colors.transparent;

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF27AE60), Color(0xFF229954)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF3498DB), // Blue
    Color(0xFFE74C3C), // Red
    Color(0xFF27AE60), // Green
    Color(0xFFF39C12), // Orange
    Color(0xFF9B59B6), // Purple
    Color(0xFF1ABC9C), // Turquoise
    Color(0xFFE67E22), // Carrot
    Color(0xFF34495E), // Wet Asphalt
    Color(0xFF16A085), // Green Sea
    Color(0xFFC0392B), // Pomegranate
    Color(0xFF2ECC71), // Emerald
    Color(0xFFF1C40F), // Sun Flower
    Color(0xFF8E44AD), // Wisteria
  ];
}
