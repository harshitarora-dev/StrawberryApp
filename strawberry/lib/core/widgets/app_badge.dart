import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_decorations.dart';

enum AppBadgeType {
  primary,
  success,
  warning,
  danger,
  info,
  neutral,
}

class AppBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AppBadgeType type;
  final VoidCallback? onTap;

  const AppBadge({
    super.key,
    required this.label,
    this.icon,
    this.type = AppBadgeType.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    switch (type) {
      case AppBadgeType.primary:
        bg = AppColors.primarySoft;
        fg = AppColors.primary;
        border = AppColors.primaryLight.withValues(alpha: 0.2);
        break;
      case AppBadgeType.success:
        bg = AppColors.emeraldSoft;
        fg = AppColors.emeraldDark;
        border = AppColors.emerald.withValues(alpha: 0.25);
        break;
      case AppBadgeType.warning:
        bg = AppColors.amberSoft;
        fg = AppColors.amberDark;
        border = AppColors.amber.withValues(alpha: 0.25);
        break;
      case AppBadgeType.danger:
        bg = AppColors.dangerSoft;
        fg = AppColors.danger;
        border = AppColors.danger.withValues(alpha: 0.25);
        break;
      case AppBadgeType.info:
        bg = AppColors.violetSoft;
        fg = AppColors.violetDark;
        border = AppColors.violet.withValues(alpha: 0.25);
        break;
      case AppBadgeType.neutral:
        bg = AppColors.surfaceAlt;
        fg = AppColors.textMuted;
        border = AppColors.border;
        break;
    }

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppDecorations.radiusFull,
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.badge.copyWith(color: fg),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppDecorations.radiusFull,
        child: content,
      );
    }

    return content;
  }
}
