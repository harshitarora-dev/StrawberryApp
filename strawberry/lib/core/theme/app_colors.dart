import 'package:flutter/material.dart';

class AppColors {
  // Brand Strawberry Palette
  static const Color primary = Color(0xFFE94464);
  static const Color primaryDark = Color(0xFFC72847);
  static const Color primaryLight = Color(0xFFFF6E8A);
  static const Color primarySoft = Color(0xFFFFF0F3);
  static const Color primaryGradientStart = Color(0xFFFF4D6D);
  static const Color primaryGradientEnd = Color(0xFFD62246);

  // Secondary & Functional Accents
  static const Color violet = Color(0xFF7C6FF0);
  static const Color violetDark = Color(0xFF5E4EE6);
  static const Color violetSoft = Color(0xFFEDE9FE);

  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldDark = Color(0xFF059669);
  static const Color emeraldSoft = Color(0xFFECFDF5);

  static const Color amber = Color(0xFFF59E0B);
  static const Color amberDark = Color(0xFFD97706);
  static const Color amberSoft = Color(0xFFFFFBEB);

  static const Color sky = Color(0xFF0EA5E9);
  static const Color skyDark = Color(0xFF0284C7);
  static const Color skySoft = Color(0xFFF0F9FF);

  static const Color indigo = Color(0xFF6366F1);
  static const Color indigoSoft = Color(0xFFEEF2FF);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSoft = Color(0xFFFEF2F2);

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF1F5F9);
  
  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFEDF2F7);

  // Typography / Neutral
  static const Color textDark = Color(0xFF0F172A);
  static const Color textBody = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textFaint = Color(0xFF94A3B8);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGradientStart, primaryGradientEnd],
  );

  static const LinearGradient violetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D399), Color(0xFF059669)],
  );

  static const LinearGradient amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
  );

  static const LinearGradient meshBgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFFFF5F7)],
  );
}
