import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/counter_chip.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/lock_badge.dart';
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
  List<Partner> _partners = [];
  int _partnersUsed = 0;
  int _partnerLimit = 5;

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
        if (mounted) {
          setState(() {
            _partners = list;
            _partnersUsed = list.length;
          });
        }
      }

      // Quota check
      final statsRes = await ApiService().getDashboardStats();
      if (statsRes != null && statsRes['data'] != null && statsRes['data']['quota'] != null) {
        final q = statsRes['data']['quota'];
        if (mounted) {
          setState(() {
            _partnerLimit = (q['partners_limit'] as num?)?.toInt() ?? 5;
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
    final bool isLimitReached = _partnersUsed >= _partnerLimit;

    return SafeArea(
      top: true,
      bottom: false,
      child: RefreshIndicator(
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
                        count: _partnersUsed,
                        limit: _partnerLimit,
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

              if (_partners.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.primaryCyan.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.handshake_outlined, color: AppColors.primaryCyan, size: 40),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Fleet Partners Found',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Attach vehicle co-owners and investor partners to distribute trip shares and record settlement payouts.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      CustomButton(
                        text: '+ Add Fleet Partner',
                        width: 180,
                        height: 42,
                        onPressed: () => widget.onNavigate('add_edit_partner'),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _partners.length,
                  itemBuilder: (context, i) {
                    final p = _partners[i];
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
                                  p.name.isNotEmpty
                                      ? p.name.substring(0, p.name.length >= 2 ? 2 : 1).toUpperCase()
                                      : 'PT',
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
                                            color: isDisabled ? AppColors.textMuted : AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        StatusChip.fromPartnerStatus(p.status),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      p.phone,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              CustomButton(
                                text: 'Ledger',
                                variant: ButtonVariant.secondary,
                                width: 75,
                                height: 32,
                                onPressed: () => widget.onNavigate('partner_ledger', args: p),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(color: AppColors.borderHairline),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Profit Share Model', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text(
                                    p.payoutType == 'percentage'
                                        ? '${p.profitSplitPercent.toInt()}% Split'
                                        : '₹${p.fixedPayoutAmount.toInt()} ${p.fixedPayoutFrequency}',
                                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Pending Payout', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${p.pendingPayout.toInt()}',
                                    style: TextStyle(
                                      color: p.pendingPayout > 0 ? AppColors.warningAmber : AppColors.successGreen,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }
}
