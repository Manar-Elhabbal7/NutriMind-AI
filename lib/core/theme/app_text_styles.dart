import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Primary font family (Poppins)
  static TextStyle get poppins => GoogleFonts.poppins();

  // Arabic font family (Almarai)
  static TextStyle get almarai => GoogleFonts.almarai();

  static TextStyle get titlePrimary => GoogleFonts.poppins(
    color: AppColors.primary,
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  static TextStyle get titleSecondary => GoogleFonts.poppins(
    color: AppColors.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static TextStyle get bodyRegular => GoogleFonts.poppins(
    color: AppColors.textSecondary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get hintStyle => GoogleFonts.poppins(
    color: AppColors.textSecondary.withAlpha(180),
    fontSize: 14,
  );

  static TextStyle get buttonTextStyle =>
      GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold);

  static TextStyle get textLink => GoogleFonts.poppins(
    color: AppColors.primary,
    fontWeight: FontWeight.bold,
  );
}
