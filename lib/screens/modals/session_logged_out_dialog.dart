import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';

class SessionLoggedOutDialog extends StatelessWidget {
  final VoidCallback onReLogin;

  const SessionLoggedOutDialog({
    super.key,
    required this.onReLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
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
                color: AppColors.criticalBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.criticalBorder),
              ),
              child: const Center(
                child: Icon(Icons.logout_rounded, color: AppColors.criticalRed, size: 28),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Session Expired / Terminated',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your operator session was logged out because your account was accessed from another device (Samsung Galaxy A34 5G).',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            CustomButton(
              text: 'Re-Login Now',
              icon: Icons.login_rounded,
              onPressed: onReLogin,
            ),
          ],
        ),
      ),
    );
  }
}
