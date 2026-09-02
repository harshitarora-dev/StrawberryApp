import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppDecorations {
  // Border Radii
  static final BorderRadius radiusXs = BorderRadius.circular(8);
  static final BorderRadius radiusSm = BorderRadius.circular(12);
  static final BorderRadius radiusMd = BorderRadius.circular(16);
  static final BorderRadius radiusLg = BorderRadius.circular(20);
  static final BorderRadius radiusXl = BorderRadius.circular(24);
  static final BorderRadius radiusFull = BorderRadius.circular(999);

  // Soft Ambient Shadows
  static final List<BoxShadow> shadowSm = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> shadowMd = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static final List<BoxShadow> shadowLg = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.28),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static final List<BoxShadow> violetGlow = [
    BoxShadow(
      color: AppColors.violet.withValues(alpha: 0.28),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // Card Decoration Helpers
  static BoxDecoration card({
    Color backgroundColor = AppColors.surface,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
    Border? border,
    Gradient? gradient,
  }) {
    return BoxDecoration(
      color: gradient == null ? backgroundColor : null,
      gradient: gradient,
      borderRadius: borderRadius ?? radiusMd,
      boxShadow: shadows ?? shadowSm,
      border: border ?? Border.all(color: AppColors.borderSubtle, width: 1),
    );
  }
}
