import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../screens/modals/locked_feature_sheet.dart';

class LockBadge extends StatelessWidget {
  final String planPrice;
  final bool isSmall;

  const LockBadge({
    super.key,
    this.planPrice = '₹99',
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warningBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_rounded,
            color: AppColors.warningAmber,
            size: isSmall ? 10 : 12,
          ),
          SizedBox(width: isSmall ? 3 : 4),
          Text(
            planPrice,
            style: TextStyle(
              color: AppColors.warningAmber,
              fontSize: isSmall ? 10 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class LockedOverlay extends StatelessWidget {
  final Widget child;
  final bool isLocked;
  final String planPrice;
  final VoidCallback? onUpgradeTap;

  const LockedOverlay({
    super.key,
    required this.child,
    this.isLocked = true,
    this.planPrice = '₹99',
    this.onUpgradeTap,
  });

  void _showLockedSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LockedFeatureSheet(
        onClose: () => Navigator.pop(ctx),
        onUpgrade: () {
          Navigator.pop(ctx);
          onUpgradeTap?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return child;

    return Stack(
      children: [
        Opacity(
          opacity: 0.45,
          child: IgnorePointer(child: child),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showLockedSheet(context),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.warningBorder, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded, color: AppColors.warningAmber, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Unlock with Pro ($planPrice)',
                        style: const TextStyle(
                          color: AppColors.warningAmber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
