import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/usage_meter.dart';
import '../../data/dummy_plan_data.dart';

class PlansAndUsageScreen extends StatelessWidget {
  final VoidCallback onBack;

  const PlansAndUsageScreen({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final usage = DummyPlanData().usage;
    final plans = DummyPlanData.allPlans;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subscription Plans & Usage Quota',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Manage tier limits, auto-renewal billing & quota meters',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Plan Quota Usage',
                      style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      'Starter Free Tier',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                UsageMeter(
                  label: 'Vehicles Inventory',
                  current: usage.vehiclesUsed,
                  limit: usage.vehicleLimit,
                ),
                const SizedBox(height: 14),
                UsageMeter(
                  label: 'Fleet Partners',
                  current: usage.partnersUsed,
                  limit: usage.partnerLimit,
                ),
                const SizedBox(height: 14),
                UsageMeter(
                  label: 'Bills Today',
                  current: usage.billsUsedToday,
                  limit: usage.dailyBillLimit,
                  note: 'Resets at 12:00 AM',
                ),
                const SizedBox(height: 14),
                UsageMeter(
                  label: 'Staff Users / Accounts',
                  current: usage.staffUsersUsed,
                  limit: usage.staffUserLimit,
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

          // Dynamic Plan Cards List by looping over DummyPlanData.allPlans
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
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
                        text: 'Active Starter Tier',
                        variant: ButtonVariant.secondary,
                        onPressed: null,
                      )
                    else ...[
                      CustomButton(
                        text: 'Upgrade with UPI (Google Pay / PhonePe autopay)',
                        icon: Icons.bolt_rounded,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Redirecting to UPI Autopay for ${plan.name}...')),
                          );
                        },
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
    );
  }
}
