import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/info_note.dart';

class DailyLimitModal extends StatelessWidget {
  final VoidCallback onUpgrade;
  final VoidCallback onDismiss;

  const DailyLimitModal({
    super.key,
    required this.onUpgrade,
    required this.onDismiss,
  });

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onUpgrade,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => DailyLimitModal(
        onUpgrade: () {
          Navigator.pop(ctx);
          onUpgrade();
        },
        onDismiss: () {
          Navigator.pop(ctx);
          onDismiss?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.warningBorder, width: 1.5),
              ),
              child: const Center(
                child: Icon(Icons.receipt_long_rounded, color: AppColors.warningAmber, size: 28),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Daily Invoice Limit Reached',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            const Text(
              'You have used 10/10 bills used today. New bills unlock at 12:00 AM or upgrade now.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            const InfoNote(
              text: 'Payment collection and returns on running bookings still work.',
              variant: InfoNoteVariant.info,
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'OK',
                    variant: ButtonVariant.secondary,
                    onPressed: onDismiss,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Upgrade',
                    icon: Icons.bolt_rounded,
                    onPressed: onUpgrade,
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
