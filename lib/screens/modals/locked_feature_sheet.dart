import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';

class LockedFeatureSheet extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onUpgrade;

  const LockedFeatureSheet({
    super.key,
    required this.onClose,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceHover,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.warningBorder, width: 1.5),
            ),
            child: const Center(
              child: Icon(Icons.lock_rounded, color: AppColors.warningAmber, size: 30),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Vehicle-Wise Yield Report Locked',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Per-vehicle profit calculation, live GPS speed tracking & FASTag toll audit is exclusive to Pro Operator plans.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          CustomButton(
            text: 'Upgrade to Pro Fleet Plan',
            icon: Icons.workspace_premium_rounded,
            onPressed: onUpgrade,
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: 'Maybe Later',
            variant: ButtonVariant.ghost,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
