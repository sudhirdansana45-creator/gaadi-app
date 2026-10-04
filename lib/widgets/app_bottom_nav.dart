import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onQuickBooking;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onQuickBooking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      height: 68,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.canvasSub.withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderHairline, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.grid_view_rounded, 'Home'),
                _buildNavItem(1, Icons.directions_car_rounded, 'Fleet'),
                _buildFloatingActionButton(),
                _buildNavItem(2, Icons.receipt_long_rounded, 'Bookings'),
                _buildNavItem(3, Icons.more_horiz_rounded, 'More'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primaryCyan : AppColors.textMuted,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primaryCyan : AppColors.textMuted,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(height: 2),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.primaryCyan,
                shape: BoxShape.circle,
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return GestureDetector(
      onTap: onQuickBooking,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x6606B6D4),
              blurRadius: 12,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: const Icon(Icons.add_rounded, color: AppColors.textDark, size: 26),
      ),
    );
  }
}
