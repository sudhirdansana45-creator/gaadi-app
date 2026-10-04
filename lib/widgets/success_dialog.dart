import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'custom_button.dart';

class SuccessDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String primaryButtonText;
  final VoidCallback onPrimaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;

  const SuccessDialog({
    super.key,
    this.icon = Icons.check_circle_rounded,
    required this.title,
    required this.message,
    this.primaryButtonText = 'Done',
    required this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    IconData icon = Icons.check_circle_rounded,
    required String title,
    required String message,
    String primaryButtonText = 'Done',
    required VoidCallback onPrimaryPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SuccessDialog(
        icon: icon,
        title: title,
        message: message,
        primaryButtonText: primaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        secondaryButtonText: secondaryButtonText,
        onSecondaryPressed: onSecondaryPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.successBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.successBorder, width: 1.5),
              ),
              child: Center(
                child: Icon(icon, color: AppColors.successGreen, size: 36),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (secondaryButtonText != null) ...[
                  Expanded(
                    child: CustomButton(
                      text: secondaryButtonText!,
                      variant: ButtonVariant.ghost,
                      onPressed: onSecondaryPressed ?? () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: CustomButton(
                    text: primaryButtonText,
                    onPressed: onPrimaryPressed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
