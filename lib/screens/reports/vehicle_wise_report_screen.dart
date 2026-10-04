import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/mock_models.dart';

class VehicleWiseReportScreen extends StatelessWidget {
  final Vehicle? vehicle;
  final VoidCallback onBack;

  const VehicleWiseReportScreen({
    super.key,
    this.vehicle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _tile('Monthly Revenue', '₹84,000', AppColors.primaryCyan),
                    _tile('Days Rented', '24 / 30 Days', AppColors.successGreen),
                    _tile('Maintenance Cost', '₹4,500', AppColors.criticalRed),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.borderHairline),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Net Vehicle Profit Share (This Month):', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const Text('₹79,500', style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.w900, fontSize: 18)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 110), // Gap to prevent overlap with bottom tab menu
        ],
      ),
    );
  }

  Widget _tile(String title, String val, Color c) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 16)),
      ],
    );
  }
}
