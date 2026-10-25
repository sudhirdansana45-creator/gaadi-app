import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/usage_meter.dart';
import '../../data/dummy_plan_data.dart';
import '../../services/api_service.dart';

class PlansAndUsageScreen extends StatefulWidget {
  final VoidCallback onBack;

  const PlansAndUsageScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<PlansAndUsageScreen> createState() => _PlansAndUsageScreenState();
}

class _PlansAndUsageScreenState extends State<PlansAndUsageScreen> {
  bool _isLoading = false;
  String _currentPlanName = 'Starter Free Tier';
  int _vehiclesUsed = 3;
  int _vehicleLimit = 5;
  int _partnersUsed = 1;
  int _partnerLimit = 2;
  int _billsUsedToday = 7;
  int _dailyBillLimit = 10;
  int _staffUsersUsed = 1;
  int _staffUserLimit = 1;

  List<PlanModel> _plans = DummyPlanData.allPlans;

  @override
  void initState() {
    super.initState();
    final usage = DummyPlanData().usage;
    _vehiclesUsed = usage.vehiclesUsed;
    _vehicleLimit = usage.vehicleLimit;
    _partnersUsed = usage.partnersUsed;
    _partnerLimit = usage.partnerLimit;
    _billsUsedToday = usage.billsUsedToday;
    _dailyBillLimit = usage.dailyBillLimit;
    _staffUsersUsed = usage.staffUsersUsed;
    _staffUserLimit = usage.staffUserLimit;

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final subRes = await ApiService().getMySubscription();
      if (subRes != null && subRes['data'] != null && mounted) {
        final d = subRes['data'];
        setState(() {
          _currentPlanName = d['plan_name']?.toString() ?? _currentPlanName;
          if (d['quota'] is Map) {
            final q = d['quota'];
            _vehiclesUsed = (q['vehicles_used'] as num?)?.toInt() ?? _vehiclesUsed;
            _vehicleLimit = (q['max_vehicles'] as num?)?.toInt() ?? _vehicleLimit;
          }
        });
      }

      final plansRes = await ApiService().getPlans();
      if (plansRes != null && plansRes['data'] is List && mounted) {
        final List list = plansRes['data'];
        if (list.isNotEmpty) {
          final mapped = list.map((p) {
            final limits = p['limits'] is Map ? p['limits'] : {};
            final featuresList = (p['features'] as List?)?.map((e) => e.toString()).toList() ?? [];
            final name = p['name']?.toString() ?? 'Plan';
            final isCurrent = name.toLowerCase() == _currentPlanName.toLowerCase() ||
                (p['price'] == 0 && _currentPlanName.toLowerCase().contains('free'));
            return PlanModel(
              id: p['id']?.toString() ?? '',
              name: name,
              pricePerMonth: (p['price'] as num?)?.toDouble() ?? 0.0,
              vehicleLimit: (limits['vehicles'] as num?)?.toInt() ?? 5,
              partnerLimit: (limits['partners'] as num?)?.toInt() ?? 2,
              dailyBillLimit: (limits['bills_per_day'] as num?)?.toInt() ?? 10,
              staffUserLimit: (limits['staff'] as num?)?.toInt() ?? 1,
              isCurrent: isCurrent,
              features: featuresList.isNotEmpty
                  ? featuresList
                  : ['Vehicle quota access', 'Partner ledger sharing', 'Invoice generator'],
            );
          }).toList();
          setState(() => _plans = mapped);
        }
      }
    } catch (_) {
      // Fallback
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUpgrade(PlanModel plan) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Requesting upgrade to ${plan.name}...')),
    );
    try {
      await ApiService().requestPlanUpgrade(plan.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upgrade request to ${plan.name} submitted successfully!')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Redirecting to UPI payment for ${plan.name}...')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Subscription Plans & Usage Quota',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Manage tier limits, auto-renewal billing & quota meters',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Active Usage Quota Meters Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Current Plan Quota Usage',
                        style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        _currentPlanName,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  UsageMeter(
                    label: 'Vehicles Inventory',
                    current: _vehiclesUsed,
                    limit: _vehicleLimit,
                  ),
                  const SizedBox(height: 14),
                  UsageMeter(
                    label: 'Fleet Partners',
                    current: _partnersUsed,
                    limit: _partnerLimit,
                  ),
                  const SizedBox(height: 14),
                  UsageMeter(
                    label: 'Bills Today',
                    current: _billsUsedToday,
                    limit: _dailyBillLimit,
                    note: 'Resets at 12:00 AM',
                  ),
                  const SizedBox(height: 14),
                  UsageMeter(
                    label: 'Staff Users / Accounts',
                    current: _staffUsersUsed,
                    limit: _staffUserLimit,
                    note: 'Staff accounts locked on Free Starter Plan',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Available Subscription Tiers',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Dynamic Plan Cards List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _plans.length,
              itemBuilder: (context, index) {
                final plan = _plans[index];
                final isCurrent = plan.isCurrent;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCurrent ? AppColors.primaryCyan : AppColors.borderSubtle,
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            plan.name,
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryCyan,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'CURRENT PLAN',
                                style: TextStyle(color: AppColors.textDark, fontSize: 10, fontWeight: FontWeight.w900),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            plan.pricePerMonth == 0 ? 'Free' : '₹${plan.pricePerMonth.toInt()}',
                            style: const TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.w900, fontSize: 24),
                          ),
                          if (plan.pricePerMonth > 0)
                            const Text(
                              ' / month',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.borderHairline),
                      const SizedBox(height: 12),

                      ...plan.features.map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    f,
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 18),

                      if (isCurrent)
                        CustomButton(
                          text: 'Active Plan',
                          variant: ButtonVariant.secondary,
                          onPressed: null,
                        )
                      else ...[
                        CustomButton(
                          text: 'Upgrade with UPI (Google Pay / PhonePe autopay)',
                          icon: Icons.bolt_rounded,
                          onPressed: () => _handleUpgrade(plan),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'Renews on the same date every month.',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ),
                      ],
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
}
