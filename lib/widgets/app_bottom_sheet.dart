import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'custom_button.dart';

class AppBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget content;
  final String? primaryActionText;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;
  final bool isPrimaryLoading;

  const AppBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.content,
    this.primaryActionText,
    this.onPrimaryAction,
    this.secondaryActionText,
    this.onSecondaryAction,
    this.isPrimaryLoading = false,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget content,
    String? primaryActionText,
    VoidCallback? onPrimaryAction,
    String? secondaryActionText,
    VoidCallback? onSecondaryAction,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: AppBottomSheet(
          title: title,
          subtitle: subtitle,
          content: content,
          primaryActionText: primaryActionText,
          onPrimaryAction: onPrimaryAction,
          secondaryActionText: secondaryActionText,
          onSecondaryAction: onSecondaryAction,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header Title & Subtitle
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Child Content
          Flexible(
            child: SingleChildScrollView(
              child: content,
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          if (primaryActionText != null || secondaryActionText != null) ...[
            Row(
              children: [
                if (secondaryActionText != null)
                  Expanded(
                    child: CustomButton(
                      text: secondaryActionText!,
                      variant: ButtonVariant.ghost,
                      onPressed: onSecondaryAction ?? () => Navigator.pop(context),
                    ),
                  ),
                if (secondaryActionText != null && primaryActionText != null)
                  const SizedBox(width: 12),
                if (primaryActionText != null)
                  Expanded(
                    child: CustomButton(
                      text: primaryActionText!,
                      isLoading: isPrimaryLoading,
                      onPressed: onPrimaryAction,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
