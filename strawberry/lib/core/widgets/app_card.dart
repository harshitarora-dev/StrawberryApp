import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.backgroundColor = AppColors.surface,
    this.gradient,
    this.borderRadius,
    this.shadows,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppDecorations.radiusMd;

    Widget content = Container(
      padding: padding,
      decoration: AppDecorations.card(
        backgroundColor: backgroundColor,
        gradient: gradient,
        borderRadius: effectiveRadius,
        shadows: shadows ?? AppDecorations.shadowSm,
        border: border,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: content,
        ),
      );
    }

    return content;
  }
}
