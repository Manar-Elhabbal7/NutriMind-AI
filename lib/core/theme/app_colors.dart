import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF43A047);
  static const Color primaryDark = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF81C784);
  static const Color primaryExtraLight = Color(0xFFE8F5E9);

  static const Color secondary = Color(0xFF7E57C2);
  static const Color secondaryDark = Color(0xFF5E35B1);
  static const Color secondaryLight = Color(0xFFB39DDB);
  static const Color secondaryExtraLight = Color(0xFFF3E5F5);

  static const Color accent = Color(0xFFFFB74D);

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF42A5F5);

  static const Color background = Color(0xFFF9FCF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color fill = Color(0xFFF4F7F5);

  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFEEF1F4);

  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color hint = Color(0xFF94A3B8);

  static const Color white = Colors.white;
  static const Color black = Color(0xFF111827);

  static const LinearGradient aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7E57C2), Color(0xFF9575CD), Color(0xFFB39DDB)],
  );

  static const LinearGradient healthGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF43A047), Color(0xFF66BB6A), Color(0xFF81C784)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF43A047), Color(0xFF66BB6A), Color(0xFF7E57C2)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8FFF8), Color(0xFFE8F5E9), Color(0xFFF3E5F5)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF9FCF9), Color(0xFFF5F3FF)],
  );

  static const LinearGradient authBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8F5FF), Color(0xFFEDE4FA), Color(0xFFFFFFFF)],
  );

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF43C878), Color(0xFF8B5CF6)],
  );
}
