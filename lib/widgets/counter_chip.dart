import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CounterChip extends StatelessWidget {
  final int count;
  final int limit;
  final String label;

  const CounterChip({
    super.key,
    required this.count,
    required this.limit,
    this.label = 'bills used today',
  });

  @override
  Widget build(BuildContext context) {
    final double ratio = limit > 0 ? (count / limit) : 0.0;

    Color textColor;
    Color bgColor;
    Color borderColor;

    if (ratio >= 1.0) {
      textColor = AppColors.criticalRed;
      bgColor = AppColors.criticalBg;
      borderColor = AppColors.criticalBorder;
    } else if (ratio >= 0.8) {
      textColor = AppColors.warningAmber;
      bgColor = AppColors.warningBg;
      borderColor = AppColors.warningBorder;
    } else {
      textColor = AppColors.primaryCyan;
      bgColor = const Color(0x1F06B6D4);
      borderColor = const Color(0x4006B6D4);
    }

    final textDisplay = limit == -1 ? '$count (Unlimited)' : '$count/$limit $label';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ratio >= 1.0
                ? Icons.warning_amber_rounded
                : (ratio >= 0.8 ? Icons.access_time_rounded : Icons.confirmation_number_rounded),
            color: textColor,
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            textDisplay,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
