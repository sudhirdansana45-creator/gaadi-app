import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_client.dart';

class NavigationItemData {
  final int index;
  final String title;
  final IconData icon;
  final String? route;
  final String? badge;

  NavigationItemData({
    required this.index,
    required this.title,
    required this.icon,
    this.route,
    this.badge,
  });
}

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static final List<NavigationItemData> mainNavItems = [
    NavigationItemData(index: 0, title: 'Dashboard', icon: Icons.dashboard_rounded),
    NavigationItemData(index: 1, title: 'Fleet Inventory', icon: Icons.directions_car_rounded, badge: '6'),
    NavigationItemData(index: 2, title: 'Bookings Ledger', icon: Icons.receipt_long_rounded, badge: '4'),
    NavigationItemData(index: 3, title: 'Customers Directory', icon: Icons.people_alt_rounded),
    NavigationItemData(index: 4, title: 'Fleet Partners', icon: Icons.handshake_rounded),
    NavigationItemData(index: 5, title: 'Reports Hub', icon: Icons.analytics_rounded),
    NavigationItemData(index: 6, title: 'Fleet Store', icon: Icons.shopping_bag_rounded, badge: 'HOT'),
    NavigationItemData(index: 7, title: 'WhatsApp Wallet', icon: Icons.mark_chat_read_rounded),
    NavigationItemData(index: 8, title: 'Users & Roles', icon: Icons.badge_rounded),
    NavigationItemData(index: 9, title: 'Subscription Plans', icon: Icons.workspace_premium_rounded),
    NavigationItemData(index: 10, title: 'Business Settings', icon: Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AppColors.canvasSub,
      child: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.directions_car_filled_rounded, color: AppColors.textDark, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gaadi Manager',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Pro Fleet Suite',
                        style: TextStyle(
                          color: AppColors.primaryCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: AppColors.borderHairline, height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              itemCount: mainNavItems.length,
              itemBuilder: (context, i) {
                final item = mainNavItems[i];
                final isSelected = selectedIndex == item.index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    onTap: () => onItemSelected(item.index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.surfaceCard : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3), width: 1)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: isSelected ? AppColors.primaryCyan : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (item.badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryCyan : AppColors.canvasLow,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                item.badge!,
                                style: TextStyle(
                                  color: isSelected ? AppColors.textDark : AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(color: AppColors.borderHairline, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: ValueListenableBuilder<Map<String, dynamic>?>(
                valueListenable: ApiClient.userNotifier,
                builder: (context, user, _) {
                  final String name = user?['name']?.toString().trim() ?? 'Operator';
                  final String business = user?['business_name']?.toString().trim() ?? 'Admin';
                  final List<String> parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
                  final String initials = parts.isNotEmpty
                      ? parts.take(2).map((p) => p[0].toUpperCase()).join()
                      : 'OP';

                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryCyan,
                        child: Text(
                          initials,
                          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              business,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.unfold_more_rounded, color: AppColors.textSecondary, size: 18),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
