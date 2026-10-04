import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/lock_badge.dart';
import '../../models/mock_models.dart';
import '../modals/locked_feature_sheet.dart';

class PartnerLedgerScreen extends StatelessWidget {
  final Partner partner;
  final VoidCallback onBack;

  const PartnerLedgerScreen({
    super.key,
    required this.partner,
    required this.onBack,
  });

  void _showLockedWhatsAppSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LockedFeatureSheet(
        onClose: () => Navigator.pop(ctx),
        onUpgrade: () {
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = partner.status == PartnerStatus.inactive;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Partner Ledger: ${partner.name}',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${partner.profitSplitPercent.toInt()}% Share • ${partner.bankAccount}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Locked Send on WhatsApp Button
              InkWell(
                onTap: () => _showLockedWhatsAppSheet(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warningBorder),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_rounded, color: AppColors.warningAmber, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'WhatsApp',
                        style: TextStyle(color: AppColors.warningAmber, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 4),
                      LockBadge(planPrice: '₹99', isSmall: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Disabled Partner Read-Only Banner
          if (isDisabled)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.criticalBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.criticalBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_rounded, color: AppColors.criticalRed, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Partner disabled. Ledger is view-only.',
                      style: TextStyle(
                        color: AppColors.criticalRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Payout Overview Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDisabled
                  ? AppColors.surfaceCard.withValues(alpha: 0.5)
                  : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metric('Gross Earnings', '₹${(partner.totalEarned * 1.3).toInt()}'),
                    _metric('Partner Net Share', '₹${partner.totalEarned.toInt()}'),
                    _metric('Pending Payout', '₹${partner.pendingPayout.toInt()}', isAlert: partner.pendingPayout > 0),
                  ],
                ),
                // Hide Record Payout action if partner is disabled
                if (!isDisabled) ...[
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Record Payout / Settlement',
                    icon: Icons.payments_rounded,
                    onPressed: () {},
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('Recent Payout & Earnings Statement', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                _historyRow('28 Sep 2026', 'Mahindra Thar (DL01AB1234) Trip Share', '+ ₹4,200', true),
                const Divider(color: AppColors.borderHairline, height: 1),
                _historyRow('24 Sep 2026', 'Bank Payout Transferred (HDFC ****4910)', '- ₹15,000', false),
                const Divider(color: AppColors.borderHairline, height: 1),
                _historyRow('20 Sep 2026', 'Royal Enfield (DL08JK7890) Trip Share', '+ ₹1,800', true),
              ],
            ),
          ),
          const SizedBox(height: 110), // Gap to prevent overlap with bottom tab menu
        ],
      ),
    );
  }

  Widget _metric(String title, String val, {bool isAlert = false}) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(color: isAlert ? AppColors.warningAmber : AppColors.primaryCyan, fontWeight: FontWeight.w800, fontSize: 16)),
      ],
    );
  }

  Widget _historyRow(String date, String desc, String amount, bool isCredit) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(date, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Text(amount, style: TextStyle(color: isCredit ? AppColors.successGreen : AppColors.criticalRed, fontWeight: FontWeight.w900, fontSize: 14)),
        ],
      ),
    );
  }
}
