import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum InfoNoteVariant { info, warning, success, critical }

class InfoNote extends StatelessWidget {
  final String text;
  final IconData icon;
  final InfoNoteVariant variant;

  const InfoNote({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
    this.variant = InfoNoteVariant.info,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;
    Color borderColor;

    switch (variant) {
      case InfoNoteVariant.warning:
        textColor = AppColors.warningAmber;
        bgColor = AppColors.warningBg;
        borderColor = AppColors.warningBorder;
        break;
      case InfoNoteVariant.success:
        textColor = AppColors.successGreen;
        bgColor = AppColors.successBg;
        borderColor = AppColors.successBorder;
        break;
      case InfoNoteVariant.critical:
        textColor = AppColors.criticalRed;
        bgColor = AppColors.criticalBg;
        borderColor = AppColors.criticalBorder;
        break;
      case InfoNoteVariant.info:
        textColor = AppColors.primaryCyan;
        bgColor = const Color(0x1F06B6D4);
        borderColor = const Color(0x4006B6D4);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
