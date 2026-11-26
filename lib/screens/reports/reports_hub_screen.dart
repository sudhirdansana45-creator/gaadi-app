import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/lock_badge.dart';
import '../../services/api_client.dart';
import '../../services/api_service.dart';
import '../modals/locked_feature_sheet.dart';

class ReportsHubScreen extends StatefulWidget {
  final Function(String route, {dynamic args}) onNavigate;

  const ReportsHubScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends State<ReportsHubScreen> {
  bool _isLoading = false;
  bool _isUnlocked = false;
  String _activePlanName = 'Free Starter';
  String _upgradePriceBadge = 'Pro';

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    // Check local client cache first
    final user = ApiClient().currentUser;
    final plan = user?['plan'] ?? user?['subscription']?['plan'];
    final planSlug = plan is Map ? (plan['slug'] ?? 'free') : 'free';
    final hasLocalPaidPlan = planSlug != 'free' && planSlug != null;

    if (hasLocalPaidPlan) {
      if (mounted) {
        setState(() {
          _isUnlocked = true;
          _activePlanName = (plan is Map ? plan['name']?.toString() : null) ?? 'Active Plan';
        });
      }
    }

    // Now check live server subscription status
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getMySubscription();
      if (res != null && res['data'] != null && mounted) {
        final d = res['data'];
        final bool hasActiveSub = d['has_active_subscription'] == true;
        final String status = (d['status']?.toString() ?? '').toLowerCase();
        final double price = (d['plan_price'] as num?)?.toDouble() ?? 0.0;
        final String planName = d['plan_name']?.toString() ?? 'Free Starter';

        // Any active subscription plan unlocks all reports dynamically!
        final bool isPaidActive = hasActiveSub || 
            (status == 'active' && price > 0) || 
            (status == 'active' && !planName.toLowerCase().contains('free'));

        setState(() {
          _isUnlocked = isPaidActive;
          _activePlanName = planName;
          if (!_isUnlocked && price > 0) {
            _upgradePriceBadge = '₹${price.toInt()}';
          }
        });
      }
    } catch (_) {
      // Keep cached state
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showLockedReportSheet(BuildContext context, String reportTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LockedFeatureSheet(
        onClose: () => Navigator.pop(ctx),
        onUpgrade: () {
          Navigator.pop(ctx);
          widget.onNavigate('plans');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F131D),
      body: SafeArea(
        top: true,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _checkSubscriptionStatus,
          color: AppColors.primaryCyan,
          backgroundColor: AppColors.surfaceCard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: LinearProgressIndicator(
                      color: AppColors.primaryCyan,
                      backgroundColor: AppColors.canvasLow,
                      minHeight: 2,
                    ),
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Business Intelligence & Reports Hub',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 19, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Revenue, Fleet P&L, Payment Modes & GST Analytics',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                      tooltip: 'Refresh Status',
                      onPressed: _checkSubscriptionStatus,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Dynamic Plan Access Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isUnlocked
                        ? const Color(0xFF00C853).withValues(alpha: 0.12)
                        : const Color(0xFFFFB300).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isUnlocked
                          ? const Color(0xFF00C853).withValues(alpha: 0.3)
                          : const Color(0xFFFFB300).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isUnlocked ? Icons.verified_rounded : Icons.lock_clock_rounded,
                        color: _isUnlocked ? const Color(0xFF00E676) : const Color(0xFFFFB300),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isUnlocked
                              ? 'Active Plan: $_activePlanName • All Reports Unlocked'
                              : 'Free Starter Plan • Upgrade to unlock all advanced analytics',
                          style: TextStyle(
                            color: _isUnlocked ? const Color(0xFF00E676) : const Color(0xFFFFB300),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!_isUnlocked)
                        GestureDetector(
                          onTap: () => widget.onNavigate('plans'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB300),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Upgrade',
                              style: TextStyle(color: Color(0xFF2E2000), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

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
                          isLocked: false, // Always open
                          onTap: () => widget.onNavigate('daily_monthly_report'),
                        ),
                        _reportCard(
                          context,
                          title: 'Vehicle-wise Yield & P&L',
                          subtitle: 'Per car revenue, ROI, idle days vs rented days breakdown.',
                          icon: Icons.directions_car_filled_rounded,
                          color: AppColors.successGreen,
                          isLocked: !_isUnlocked,
                          onTap: () {
                            if (!_isUnlocked) {
                              _showLockedReportSheet(context, 'Vehicle-wise Yield & P&L');
                            } else {
                              widget.onNavigate('vehicle_wise_report');
                            }
                          },
                        ),
                        _reportCard(
                          context,
                          title: 'Partner Profit Payouts',
                          subtitle: 'Co-investor gross earnings, split calculation and payout status.',
                          icon: Icons.handshake_rounded,
                          color: AppColors.warningAmber,
                          isLocked: !_isUnlocked,
                          onTap: () {
                            if (!_isUnlocked) {
                              _showLockedReportSheet(context, 'Partner Profit Payouts');
                            } else {
                              widget.onNavigate('partner_ledger');
                            }
                          },
                        ),
                        _reportCard(
                          context,
                          title: 'Maintenance & Service Ledger',
                          subtitle: 'Vehicle repair costs, oil changes & vendor settlement logs.',
                          icon: Icons.build_circle_rounded,
                          color: AppColors.criticalRed,
                          isLocked: !_isUnlocked,
                          onTap: () {
                            if (!_isUnlocked) {
                              _showLockedReportSheet(context, 'Maintenance & Service Ledger');
                            } else {
                              widget.onNavigate('maintenance_report');
                            }
                          },
                        ),
                        _reportCard(
                          context,
                          title: 'GST & Tax Accounting Export',
                          subtitle: 'One-click Excel & PDF exports for CA audit & GST filing.',
                          icon: Icons.file_download_rounded,
                          color: AppColors.infoBlue,
                          isLocked: !_isUnlocked,
                          onTap: () {
                            if (!_isUnlocked) {
                              _showLockedReportSheet(context, 'GST & Tax Export');
                            } else {
                              widget.onNavigate('gst_report');
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
                      LockBadge(planPrice: _upgradePriceBadge),
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
