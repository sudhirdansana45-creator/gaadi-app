import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/counter_chip.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/lock_badge.dart';
import '../../data/mock_data.dart';
import '../../data/dummy_plan_data.dart';
import '../../models/mock_models.dart';
import '../../services/api_service.dart';
import '../modals/locked_feature_sheet.dart';

class PartnersListScreen extends StatefulWidget {
  final Function(String route, {dynamic args}) onNavigate;

  const PartnersListScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<PartnersListScreen> createState() => _PartnersListScreenState();
}

class _PartnersListScreenState extends State<PartnersListScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getPartners();
      if (res != null && res['data'] != null) {
        final list = (res['data'] as List)
            .map((item) => Partner.fromJson(item as Map<String, dynamic>))
            .toList();
        if (mounted && list.isNotEmpty) {
          setState(() {
            MockData.partners = list;
          });
        }
      }
    } catch (_) {
      // Offline fallback
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showLimitReachedSheet(BuildContext context) {
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
    final isLimitReached = DummyPlanData().usage.isPartnerLimitReached;

    return RefreshIndicator(
      onRefresh: _loadPartners,
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
            // Counter Chip at the top
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CounterChip(
                      count: DummyPlanData().usage.partnersUsed,
                      limit: DummyPlanData().usage.partnerLimit,
                      label: 'partners used',
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => widget.onNavigate('plans'),
                      child: const Text(
                        'Upgrade',
                        style: TextStyle(
                          color: AppColors.primaryCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primaryCyan,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isLimitReached)
                  InkWell(
                    onTap: () => _showLimitReachedSheet(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.warningBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warningBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_rounded, color: AppColors.warningAmber, size: 14),
                          SizedBox(width: 6),
                          Text(
                            '+ Add Partner',
                            style: TextStyle(
                              color: AppColors.warningAmber,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 6),
                          LockBadge(planPrice: '₹99', isSmall: true),
                        ],
                      ),
                    ),
                  )
                else
                  CustomButton(
                    text: '+ Add Partner',
                    width: 120,
                    height: 38,
                    onPressed: () => widget.onNavigate('add_edit_partner'),
                  ),
              ],
            ),
          const SizedBox(height: 16),

          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fleet Co-Owners & Partners',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'Attached Vehicle Investors & Profit Sharing',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: MockData.partners.length,
            itemBuilder: (context, i) {
              final p = MockData.partners[i];
              final isDisabled = p.status == PartnerStatus.inactive;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDisabled
                      ? AppColors.surfaceCard.withValues(alpha: 0.5)
                      : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDisabled ? AppColors.borderHairline : AppColors.borderSubtle,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: isDisabled
                              ? AppColors.canvasLow
                              : AppColors.primaryCyan.withValues(alpha: 0.2),
                          child: Text(
                            p.name.substring(0, 2).toUpperCase(),
                            style: TextStyle(
                              color: isDisabled ? AppColors.textMuted : AppColors.primaryCyan,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    p.name,
                                    style: TextStyle(
                                      color: isDisabled ? AppColors.textSecondary : AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (isDisabled) ...[
                                    const SizedBox(width: 8),
                                    StatusChip.disabled(label: 'Disabled'),
                                  ],
                                ],
                              ),
                              Text(
                                '${p.phone} • ${p.email}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryCyan.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${p.profitSplitPercent.toInt()}% Profit Split',
                            style: const TextStyle(color: AppColors.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.borderHairline),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _col('Attached Vehicles', '${p.attachedVehiclesCount} Cars'),
                        _col('Lifetime Earned', '₹${p.totalEarned.toInt()}'),
                        // Pending Payout STILL visible even when disabled!
                        _col('Pending Payout', '₹${p.pendingPayout.toInt()}', isHigh: p.pendingPayout > 0),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'View Ledger & Payout',
                            variant: ButtonVariant.secondary,
                            height: 38,
                            onPressed: () => widget.onNavigate('partner_ledger', args: p),
                          ),
                        ),
                        const SizedBox(width: 10),
                        CustomButton(
                          text: 'Edit',
                          variant: ButtonVariant.outline,
                          width: 80,
                          height: 38,
                          onPressed: () => widget.onNavigate('add_edit_partner', args: p),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 110), // Gap to prevent overlap with bottom tab menu
        ],
      ),
    ),
  );
}

  Widget _col(String title, String val, {bool isHigh = false}) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(
            color: isHigh ? AppColors.warningAmber : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
