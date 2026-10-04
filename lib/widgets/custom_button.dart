import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ButtonVariant { primary, secondary, outline, destructive, ghost }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == ButtonVariant.primary) {
      return Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4006B6D4),
              blurRadius: 12,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDark),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 18, color: AppColors.textDark),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          text,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
    }

    Color bgColor = AppColors.surfaceCard;
    Color borderCol = AppColors.borderSubtle;
    Color textCol = AppColors.textPrimary;

    if (variant == ButtonVariant.secondary) {
      bgColor = AppColors.surfaceHover;
      borderCol = AppColors.borderSubtle;
      textCol = AppColors.textPrimary;
    } else if (variant == ButtonVariant.outline) {
      bgColor = Colors.transparent;
      borderCol = AppColors.primaryCyan.withOpacity(0.5);
      textCol = AppColors.primaryCyan;
    } else if (variant == ButtonVariant.destructive) {
      bgColor = AppColors.criticalBg;
      borderCol = AppColors.criticalBorder;
      textCol = AppColors.criticalRed;
    } else if (variant == ButtonVariant.ghost) {
      bgColor = Colors.transparent;
      borderCol = Colors.transparent;
      textCol = AppColors.textSecondary;
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: bgColor,
          side: BorderSide(color: borderCol, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: textCol),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: textCol),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: textCol,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
