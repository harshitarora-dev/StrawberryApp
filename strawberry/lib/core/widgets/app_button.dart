import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_decorations.dart';

enum AppButtonVariant { primary, secondary, outline, text, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final AppButtonVariant variant;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.variant = AppButtonVariant.primary,
    this.width,
    this.height = 48,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppDecorations.radiusSm;

    Color bg;
    Color fg;
    Border? border;
    List<BoxShadow>? shadows;
    Gradient? gradient;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = AppColors.primary;
        fg = Colors.white;
        gradient = AppColors.primaryGradient;
        shadows = AppDecorations.primaryGlow;
        break;
      case AppButtonVariant.secondary:
        bg = AppColors.primarySoft;
        fg = AppColors.primaryDark;
        break;
      case AppButtonVariant.outline:
        bg = AppColors.surface;
        fg = AppColors.textDark;
        border = Border.all(color: AppColors.border, width: 1.2);
        break;
      case AppButtonVariant.text:
        bg = Colors.transparent;
        fg = AppColors.primary;
        break;
      case AppButtonVariant.danger:
        bg = AppColors.danger;
        fg = Colors.white;
        break;
    }

    final isInteractive = onPressed != null && !loading;

    return AnimatedOpacity(
      opacity: isInteractive ? 1.0 : 0.6,
      duration: const Duration(milliseconds: 150),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: gradient == null ? bg : null,
          gradient: gradient,
          borderRadius: radius,
          border: border,
          boxShadow: isInteractive && variant == AppButtonVariant.primary ? shadows : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: isInteractive ? onPressed : null,
            borderRadius: radius,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(fg),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 18, color: fg),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              style: AppTypography.button.copyWith(color: fg),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
