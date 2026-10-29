import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/lock_badge.dart';
import '../../data/dummy_plan_data.dart';
import '../modals/locked_feature_sheet.dart';

class ReportsHubScreen extends StatelessWidget {
  final Function(String route, {dynamic args}) onNavigate;

  const ReportsHubScreen({
    super.key,
    required this.onNavigate,
  });

  void _showLockedReportSheet(BuildContext context, String reportTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LockedFeatureSheet(
        onClose: () => Navigator.pop(ctx),
        onUpgrade: () {
          Navigator.pop(ctx);
          onNavigate('plans');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine locked status from DummyPlanData (Free plan has only Daily & Monthly open)
    final isFreePlan = DummyPlanData().activeState == PlanState.free;

    return SafeArea(
      top: true,
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Business Intelligence & Reports Hub',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Revenue, Fleet P&L, Payment Modes & GST Analytics',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 700 ? 2 : 1;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: crossCount == 2 ? 1.55 : 1.65,
                children: [
                  _reportCard(
                    context,
                    title: 'Daily & Monthly Revenue',
                    subtitle: 'Collection trends, cash vs UPI breakdown and date-range filters.',
                    icon: Icons.bar_chart_rounded,
                    color: AppColors.primaryCyan,
                    isLocked: false, // Always open on Free starter plan
                    onTap: () => onNavigate('daily_monthly_report'),
                  ),
                  _reportCard(
                    context,
                    title: 'Vehicle-wise Yield & P&L',
                    subtitle: 'Per car revenue, ROI, idle days vs rented days breakdown.',
                    icon: Icons.directions_car_filled_rounded,
                    color: AppColors.successGreen,
                    isLocked: isFreePlan, // Locked on Free plan
                    onTap: () {
                      if (isFreePlan) {
                        _showLockedReportSheet(context, 'Vehicle-wise Yield & P&L');
                      } else {
                        onNavigate('vehicle_wise_report');
                      }
                    },
                  ),
                  _reportCard(
                    context,
                    title: 'Partner Profit Payouts',
                    subtitle: 'Co-investor gross earnings, split calculation and payout status.',
                    icon: Icons.handshake_rounded,
                    color: AppColors.warningAmber,
                    isLocked: isFreePlan, // Locked on Free plan
                    onTap: () {
                      if (isFreePlan) {
                        _showLockedReportSheet(context, 'Partner Profit Payouts');
                      } else {
                        onNavigate('partner_ledger');
                      }
                    },
                  ),
                  _reportCard(
                    context,
                    title: 'Maintenance & Service Ledger',
                    subtitle: 'Vehicle repair costs, oil changes & vendor settlement logs.',
                    icon: Icons.build_circle_rounded,
                    color: AppColors.criticalRed,
                    isLocked: isFreePlan, // Locked on Free plan
                    onTap: () {
                      if (isFreePlan) {
                        _showLockedReportSheet(context, 'Maintenance & Service Ledger');
                      } else {
                        onNavigate('maintenance_report');
                      }
                    },
                  ),
                  _reportCard(
                    context,
                    title: 'GST & Tax Accounting Export',
                    subtitle: 'One-click Excel & PDF exports for CA audit & GST filing.',
                    icon: Icons.file_download_rounded,
                    color: AppColors.infoBlue,
                    isLocked: isFreePlan, // Locked on Free plan
                    onTap: () {
                      if (isFreePlan) {
                        _showLockedReportSheet(context, 'GST & Tax Export');
                      } else {
                        onNavigate('gst_report');
                      }
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 110), // Gap to prevent overlap with bottom tab menu
        ],
      ),
    ),
  );
  }

  Widget _reportCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isLocked,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isLocked
            ? AppColors.surfaceCard.withValues(alpha: 0.6)
            : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLocked ? AppColors.borderHairline : AppColors.borderSubtle,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isLocked ? 0.08 : 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: isLocked ? AppColors.textMuted : color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: isLocked ? AppColors.textSecondary : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (isLocked) ...[
                      const SizedBox(width: 6),
                      const LockBadge(planPrice: '₹99'),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: isLocked ? 'Unlock Report' : 'View Report',
            variant: isLocked ? ButtonVariant.outline : ButtonVariant.secondary,
            height: 38,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
