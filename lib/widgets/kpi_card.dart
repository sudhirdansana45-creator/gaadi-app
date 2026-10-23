import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final String? trendText;
  final bool isPositiveTrend;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor = AppColors.primaryCyan,
    this.trendText,
    this.isPositiveTrend = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: iconColor.withValues(alpha: 0.2), width: 1),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            if (trendText != null || subtitle != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  if (trendText != null) ...[
                    Icon(
                      isPositiveTrend ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: isPositiveTrend ? AppColors.successGreen : AppColors.criticalRed,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trendText!,
                      style: TextStyle(
                        color: isPositiveTrend ? AppColors.successGreen : AppColors.criticalRed,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (subtitle != null)
                    Expanded(
                      child: Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
