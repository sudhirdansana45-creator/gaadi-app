import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class UsageMeter extends StatelessWidget {
  final String label;
  final int current;
  final int limit; // -1 for unlimited
  final String? note;
  final String? unit;

  const UsageMeter({
    super.key,
    required this.label,
    required this.current,
    required this.limit,
    this.note,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUnlimited = limit == -1;
    final double ratio = isUnlimited ? 0.2 : (limit > 0 ? (current / limit).clamp(0.0, 1.0) : 0.0);

    Color progressColor;
    if (ratio >= 1.0) {
      progressColor = AppColors.criticalRed;
    } else if (ratio >= 0.8) {
      progressColor = AppColors.warningAmber;
    } else {
      progressColor = AppColors.primaryCyan;
    }

    final String displayValue = isUnlimited
        ? '$current (Unlimited)'
        : '$current / $limit ${unit ?? ''}'.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              displayValue,
              style: TextStyle(
                color: progressColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: isUnlimited ? 1.0 : ratio,
            minHeight: 8,
            backgroundColor: AppColors.canvasLow,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
        if (note != null && note!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            note!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
