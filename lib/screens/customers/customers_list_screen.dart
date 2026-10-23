import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/status_chip.dart';
import '../../data/mock_data.dart';

class CustomersListScreen extends StatefulWidget {
  final Function(String route, {dynamic args}) onNavigate;

  const CustomersListScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  String _search = '';
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Verified', 'Blacklisted', 'Due'];

  @override
  Widget build(BuildContext context) {
    final list = MockData.customers.where((c) {
      // Filter category logic
      if (_selectedFilter == 'Verified' && (!c.isVerified || c.isBlacklisted)) return false;
      if (_selectedFilter == 'Blacklisted' && !c.isBlacklisted) return false;
      if (_selectedFilter == 'Due' && c.outstandingBalance <= 0) return false;

      // Search logic
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return c.name.toLowerCase().contains(q) ||
            c.phone.contains(q) ||
            c.drivingLicense.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _search = val),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search customer by name, mobile or driving license...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                    filled: true,
                    fillColor: AppColors.canvasLow,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              CustomButton(
                text: '+ Renter',
                width: 100,
                height: 48,
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = filter);
                      }
                    },
                    selectedColor: AppColors.primaryCyan.withValues(alpha: 0.2),
                    backgroundColor: AppColors.surfaceCard,
                    checkmarkColor: AppColors.primaryCyan,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primaryCyan : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primaryCyan : AppColors.borderSubtle,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          if (list.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Text(
                'No customers found matching filter criteria.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final c = list[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.isBlacklisted
                        ? AppColors.criticalBg.withValues(alpha: 0.4)
                        : AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: c.isBlacklisted ? AppColors.criticalBorder : AppColors.borderSubtle,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: c.isBlacklisted
                                ? AppColors.criticalBg
                                : AppColors.surfaceHover,
                            child: Text(
                              c.name.substring(0, 2).toUpperCase(),
                              style: TextStyle(
                                color: c.isBlacklisted
                                    ? AppColors.criticalRed
                                    : AppColors.primaryCyan,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      c.name,
                                      style: TextStyle(
                                        color: c.isBlacklisted
                                            ? AppColors.criticalRed
                                            : AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (c.isBlacklisted)
                                      StatusChip.blacklisted()
                                    else if (c.isVerified)
                                      StatusChip.verified(),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${c.phone} • DL: ${c.drivingLicense}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${c.totalRentals} Total Trips • ₹${c.totalSpent.toInt()} Spent',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (c.outstandingBalance > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.warningBg,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.warningBorder),
                                  ),
                                  child: Text(
                                    'Due: ₹${c.outstandingBalance.toInt()}',
                                    style: const TextStyle(
                                      color: AppColors.warningAmber,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else
                                const Text(
                                  'Clear Ledger',
                                  style: TextStyle(
                                    color: AppColors.successGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              CustomButton(
                                text: 'Profile',
                                variant: ButtonVariant.secondary,
                                width: 75,
                                height: 32,
                                onPressed: () => widget.onNavigate('customer_profile', args: c),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (c.isBlacklisted && c.blacklistReason != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.criticalBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.criticalBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppColors.criticalRed, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Reason: ${c.blacklistReason}',
                                  style: const TextStyle(
                                    color: AppColors.criticalRed,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
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
