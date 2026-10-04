import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bottom_sheet.dart';

class UpiPlaceholderSheet extends StatelessWidget {
  final String planName;
  final double amount;

  const UpiPlaceholderSheet({
    super.key,
    required this.planName,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: 'Upgrade via UPI Autopay',
      subtitle: 'Google Pay / PhonePe / Paytm Subscription',
      primaryActionText: 'Proceed to Pay ₹${amount.toInt()}',
      onPrimaryAction: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment gateway will be connected in live release.'),
            backgroundColor: AppColors.primaryCyan,
          ),
        );
      },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planName,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Text(
                      'Auto-renews monthly',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                Text(
                  '₹${amount.toInt()}/mo',
                  style: const TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Select UPI App', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _upiOption(Icons.account_balance_wallet_rounded, 'Google Pay'),
              _upiOption(Icons.phonelink_ring_rounded, 'PhonePe'),
              _upiOption(Icons.payment_rounded, 'Paytm UPI'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _upiOption(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceHover,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Icon(icon, color: AppColors.primaryCyan, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}
