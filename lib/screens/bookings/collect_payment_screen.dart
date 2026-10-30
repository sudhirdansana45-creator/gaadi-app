import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/lock_badge.dart';
import '../../screens/modals/locked_feature_sheet.dart';
import '../../models/mock_models.dart';
import '../../services/api_service.dart';

class CollectPaymentScreen extends StatefulWidget {
  final Booking? booking;
  final String? bookingId;
  final VoidCallback onCollected;
  final VoidCallback onCancel;

  const CollectPaymentScreen({
    super.key,
    this.booking,
    this.bookingId,
    required this.onCollected,
    required this.onCancel,
  });

  @override
  State<CollectPaymentScreen> createState() => _CollectPaymentScreenState();
}

class _CollectPaymentScreenState extends State<CollectPaymentScreen> {
  final _amountController = TextEditingController();
  final _refController = TextEditingController();
  String _selectedMode = 'UPI (GPay)';
  
  Booking? _booking;
  bool _isLoadingBooking = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    if (_booking != null) {
      _initAmountFromBooking(_booking!);
    } else if (widget.bookingId != null) {
      _fetchBooking();
    }
  }

  void _initAmountFromBooking(Booking b) {
    if (b.pendingAmount > 0) {
      _amountController.text = b.pendingAmount.toInt().toString();
    }
  }

  Future<void> _fetchBooking() async {
    setState(() => _isLoadingBooking = true);
    try {
      final res = await ApiService().getBookingDetail(widget.bookingId!);
      if (res != null && res['data'] != null && mounted) {
        final b = Booking.fromJson(res['data'] as Map<String, dynamic>);
        setState(() {
          _booking = b;
          _initAmountFromBooking(b);
        });
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoadingBooking = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    super.dispose();
  }

  void _showSuccessState(double enteredAmount, double remaining) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.successBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.successBorder, width: 1.5),
              ),
              child: const Center(
                child: Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 36),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Payment Collected!',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '₹${enteredAmount.toInt()} received via $_selectedMode.\n${remaining > 0 ? "Remaining due: ₹${remaining.toInt()}" : "Bill fully settled!"}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Share Invoice Action
            CustomButton(
              text: 'Share Invoice (PDF)',
              icon: Icons.share_rounded,
              variant: ButtonVariant.primary,
              onPressed: () {
                Navigator.pop(ctx);
                widget.onCollected();
              },
            ),
            const SizedBox(height: 10),

            // Send on WhatsApp with LockBadge
            InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (lCtx) => LockedFeatureSheet(
                    onClose: () => Navigator.pop(lCtx),
                    onUpgrade: () => Navigator.pop(lCtx),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.canvasLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warningBorder),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mark_chat_read_rounded, color: AppColors.warningAmber, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Send on WhatsApp',
                      style: TextStyle(color: AppColors.warningAmber, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    LockBadge(planPrice: 'PRO', isSmall: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Done',
              variant: ButtonVariant.ghost,
              onPressed: () {
                Navigator.pop(ctx);
                widget.onCollected();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingBooking) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Collect Payment'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: widget.onCancel,
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryCyan),
        ),
      );
    }

    if (_booking == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Collect Payment'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: widget.onCancel,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.criticalRed.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.search_off_rounded, color: AppColors.criticalRed, size: 48),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Booking Record Not Found',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The requested booking record does not exist or may have been deleted.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Back to Bookings',
                  width: 180,
                  onPressed: widget.onCancel,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentBooking = _booking!;
    final double totalPendingDue = currentBooking.pendingAmount;
    final double enteredAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final double remainingBalance = (totalPendingDue - enteredAmount).clamp(0.0, 999999.0);
    final bool isPartial = remainingBalance > 0;

    final hasPaymentHistory = currentBooking.advancePaid > 0 || currentBooking.securityDeposit > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Collect Payment (${currentBooking.id})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onCancel,
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Form Card
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Renter: ${currentBooking.customerName}',
                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                'Vehicle: ${currentBooking.vehicleName} (${currentBooking.vehicleRegNumber})',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: totalPendingDue > 0 ? AppColors.warningBg : AppColors.successBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: totalPendingDue > 0 ? AppColors.warningBorder : AppColors.successBorder),
                          ),
                          child: Text(
                            totalPendingDue > 0 ? 'Total Due: ₹${totalPendingDue.toInt()}' : 'Fully Paid',
                            style: TextStyle(
                              color: totalPendingDue > 0 ? AppColors.warningAmber : AppColors.successGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.borderHairline),
                    const SizedBox(height: 16),

                    // 1. Amount Input
                    CustomTextField(
                      label: 'Collection Amount (₹)',
                      hintText: 'Enter amount',
                      controller: _amountController,
                      prefixText: '₹',
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // Live Partial Balance Indicator Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isPartial ? AppColors.warningBg : AppColors.successBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isPartial ? AppColors.warningBorder : AppColors.successBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isPartial ? Icons.pie_chart_outline_rounded : Icons.check_circle_outline_rounded,
                                color: isPartial ? AppColors.warningAmber : AppColors.successGreen,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isPartial ? 'Partial Payment (Remaining Due):' : 'Full Payment Settlement:',
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Text(
                            isPartial ? '₹${remainingBalance.toInt()}' : '₹0 (Settled)',
                            style: TextStyle(
                              color: isPartial ? AppColors.warningAmber : AppColors.successGreen,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Payment Mode Selector
                    const Text('Payment Mode', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['UPI (GPay)', 'Cash', 'Card Swipe', 'Bank Transfer'].map((mode) {
                        final selected = _selectedMode == mode;
                        return ChoiceChip(
                          label: Text(mode),
                          selected: selected,
                          onSelected: (val) => setState(() => _selectedMode = mode),
                          selectedColor: AppColors.primaryCyan,
                          backgroundColor: AppColors.canvasLow,
                          labelStyle: TextStyle(
                            color: selected ? AppColors.textDark : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Payment Reference / Transaction ID',
                      hintText: 'e.g. UTR / Receipt No',
                      controller: _refController,
                      prefixIcon: Icons.receipt_long_rounded,
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.borderHairline),
                    const SizedBox(height: 16),

                    // 3. Payment History Log
                    const Text('Payment History Log', style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),
                    if (hasPaymentHistory) ...[
                      if (currentBooking.advancePaid > 0)
                        _historyRow(
                          'Advance Booking Deposit',
                          '₹${currentBooking.advancePaid.toInt()}',
                          currentBooking.paymentMode,
                          '${currentBooking.startDate.day}-${currentBooking.startDate.month}-${currentBooking.startDate.year}',
                        ),
                      if (currentBooking.securityDeposit > 0)
                        _historyRow(
                          'Security Deposit Held',
                          '₹${currentBooking.securityDeposit.toInt()}',
                          currentBooking.paymentMode,
                          '${currentBooking.startDate.day}-${currentBooking.startDate.month}-${currentBooking.startDate.year}',
                        ),
                    ] else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No prior advance or deposit recorded for this booking.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),

                    const SizedBox(height: 24),

                    CustomButton(
                      text: 'Confirm & Record Payment',
                      icon: Icons.check_circle_rounded,
                      isLoading: _isLoading,
                      onPressed: () async {
                        if (enteredAmount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter an amount to collect'),
                              backgroundColor: AppColors.criticalRed,
                            ),
                          );
                          return;
                        }

                        setState(() => _isLoading = true);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await ApiService().recordBookingPayment(
                            currentBooking.id,
                            amount: enteredAmount,
                            paymentMode: _selectedMode,
                            transactionRef: _refController.text.trim(),
                          );
                          if (mounted) {
                            setState(() => _isLoading = false);
                            _showSuccessState(enteredAmount, remainingBalance);
                          }
                        } catch (e) {
                          final msg = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
                          if (mounted) {
                            setState(() => _isLoading = false);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: AppColors.criticalRed,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyRow(String title, String amount, String mode, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.canvasLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              Text('$mode • $date', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
          Text(amount, style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }
}
