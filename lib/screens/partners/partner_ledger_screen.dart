import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/lock_badge.dart';
import '../../models/mock_models.dart';
import '../../services/api_service.dart';
import '../modals/locked_feature_sheet.dart';

class PartnerLedgerScreen extends StatefulWidget {
  final Partner? partner;
  final String? partnerId;
  final VoidCallback onBack;

  const PartnerLedgerScreen({
    super.key,
    this.partner,
    this.partnerId,
    required this.onBack,
  });

  @override
  State<PartnerLedgerScreen> createState() => _PartnerLedgerScreenState();
}

class _PartnerLedgerScreenState extends State<PartnerLedgerScreen> {
  Partner? _partner;
  bool _isLoading = false;
  double _grossEarnings = 0;
  double _partnerShare = 0;
  double _pendingPayout = 0;
  List<Map<String, dynamic>> _transactions = [];

  Partner get currentPartner => _partner!;

  @override
  void initState() {
    super.initState();
    _partner = widget.partner;
    if (_partner != null) {
      _partnerShare = _partner!.totalEarned;
      _grossEarnings = _partner!.totalEarned;
      _pendingPayout = _partner!.pendingPayout;
      _loadLedger();
    } else if (widget.partnerId != null) {
      _fetchPartner();
    }
  }

  Future<void> _fetchPartner() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getPartners();
      if (res != null && res['data'] is List && mounted) {
        final list = (res['data'] as List)
            .map((item) => Partner.fromJson(item as Map<String, dynamic>))
            .toList();
        final match = list.where((p) => p.id == widget.partnerId).firstOrNull;
        if (match != null) {
          setState(() {
            _partner = match;
            _partnerShare = match.totalEarned;
            _grossEarnings = match.totalEarned;
            _pendingPayout = match.pendingPayout;
          });
          _loadLedger();
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadLedger() async {
    if (_partner == null) return;
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getPartnerLedger(currentPartner.id);
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
                if (amt <= 0 || _partner == null) return;
                setDlgState(() => isSaving = true);
                try {
                  await ApiService().recordPartnerPayout(
                    currentPartner.id,
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
    if (_isLoading && _partner == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Partner Ledger'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: widget.onBack,
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryCyan),
        ),
      );
    }

    if (_partner == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Partner Ledger'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: widget.onBack,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off_outlined, size: 64, color: AppColors.textMuted.withAlpha(120)),
                const SizedBox(height: 16),
                const Text(
                  'Partner Record Not Found',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The requested partner details could not be found or have been deleted.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Back to Fleet Partners',
                  variant: ButtonVariant.secondary,
                  onPressed: widget.onBack,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isDisabled = currentPartner.status == PartnerStatus.inactive;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Partner Ledger: ${currentPartner.name}'),
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
                        'Partner Ledger: ${currentPartner.name}',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${currentPartner.profitSplitPercent.toInt()}% Share • ${currentPartner.bankAccount}',
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
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, color: AppColors.textMuted.withAlpha(120), size: 40),
                          const SizedBox(height: 10),
                          const Text(
                            'No Ledger Transactions Found',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Trip profit shares and payout records for this partner will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
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
