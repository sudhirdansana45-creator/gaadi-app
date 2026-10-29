import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/lock_badge.dart';
import '../../models/mock_models.dart';
import '../../services/api_service.dart';
import '../modals/locked_feature_sheet.dart';

class PartnerLedgerScreen extends StatefulWidget {
  final Partner partner;
  final VoidCallback onBack;

  const PartnerLedgerScreen({
    super.key,
    required this.partner,
    required this.onBack,
  });

  @override
  State<PartnerLedgerScreen> createState() => _PartnerLedgerScreenState();
}

class _PartnerLedgerScreenState extends State<PartnerLedgerScreen> {
  bool _isLoading = false;
  double _grossEarnings = 0;
  double _partnerShare = 0;
  double _pendingPayout = 0;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _partnerShare = widget.partner.totalEarned;
    _grossEarnings = widget.partner.totalEarned * 1.3;
    _pendingPayout = widget.partner.pendingPayout;
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getPartnerLedger(widget.partner.id);
      if (res != null && res['data'] != null && mounted) {
        final data = res['data'];
        setState(() {
          _grossEarnings = (data['total_earnings'] as num?)?.toDouble() ?? _grossEarnings;
          _pendingPayout = (data['current_balance'] as num?)?.toDouble() ?? _pendingPayout;
          _partnerShare = _grossEarnings - _pendingPayout;
          if (data['transactions'] is List) {
            _transactions = List<Map<String, dynamic>>.from(data['transactions']);
          }
        });
      }
    } catch (_) {
      // Graceful offline fallback
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRecordPayoutDialog() {
    final amountCtrl = TextEditingController(text: _pendingPayout > 0 ? _pendingPayout.toInt().toString() : '5000');
    final noteCtrl = TextEditingController(text: 'Bank Settlement');
    String mode = 'bank';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Record Partner Payout', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Payout Amount (₹)',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: mode,
                dropdownColor: AppColors.surfaceCard,
                style: const TextStyle(color: AppColors.textPrimary),
                items: const [
                  DropdownMenuItem(value: 'bank', child: Text('Bank Transfer (NEFT/IMPS)')),
                  DropdownMenuItem(value: 'upi', child: Text('UPI Transfer')),
                  DropdownMenuItem(value: 'cash', child: Text('Cash in Hand')),
                ],
                onChanged: (val) {
                  if (val != null) setDlgState(() => mode = val);
                },
                decoration: const InputDecoration(
                  labelText: 'Payment Mode',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Remarks / Reference ID',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            CustomButton(
              text: 'Confirm Payout',
              isLoading: isSaving,
              width: 140,
              height: 40,
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
                if (amt <= 0) return;
                setDlgState(() => isSaving = true);
                try {
                  await ApiService().recordPartnerPayout(
                    widget.partner.id,
                    amount: amt,
                    mode: mode,
                    note: noteCtrl.text.trim(),
                  );
                } catch (_) {
                  // Fallback
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _loadLedger();
              },
            ),
          ],
        ),
      ),
    );
  }

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
    final isDisabled = widget.partner.status == PartnerStatus.inactive;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Partner Ledger: ${widget.partner.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onBack,
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadLedger,
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
                      Text(
                        'Partner Ledger: ${widget.partner.name}',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${widget.partner.profitSplitPercent.toInt()}% Share • ${widget.partner.bankAccount}',
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
                      _metric('Gross Earnings', '₹${_grossEarnings.toInt()}'),
                      _metric('Partner Net Share', '₹${_partnerShare.toInt()}'),
                      _metric('Pending Payout', '₹${_pendingPayout.toInt()}', isAlert: _pendingPayout > 0),
                    ],
                  ),
                  // Hide Record Payout action if partner is disabled
                  if (!isDisabled) ...[
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Record Payout / Settlement',
                      icon: Icons.payments_rounded,
                      onPressed: _showRecordPayoutDialog,
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
              child: _transactions.isNotEmpty
                  ? Column(
                      children: _transactions.map((tx) {
                        final isCredit = tx['type'] == 'credit';
                        final amt = (tx['amount'] as num?)?.toDouble() ?? 0;
                        final date = (tx['created_at'] as String?)?.split('T').first ?? 'Recent';
                        final note = tx['note'] ?? tx['payout_mode'] ?? 'Transaction';
                        return Column(
                          children: [
                            _historyRow(date, note, '${isCredit ? "+" : "-"} ₹${amt.toInt()}', isCredit),
                            const Divider(color: AppColors.borderHairline, height: 1),
                          ],
                        );
                      }).toList(),
                    )
                  : Column(
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
      ),
    ),
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
