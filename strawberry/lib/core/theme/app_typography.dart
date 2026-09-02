import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle get display => GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle get h1 => GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static TextStyle get h3 => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    letterSpacing: -0.1,
    height: 1.3,
  );

  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textBody,
    height: 1.45,
  );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    color: AppColors.textBody,
    height: 1.4,
  );

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    height: 1.35,
  );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textFaint,
    letterSpacing: 0.2,
  );

  static TextStyle get button => GoogleFonts.plusJakartaSans(
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );

  static TextStyle get badge => GoogleFonts.plusJakartaSans(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );
}
