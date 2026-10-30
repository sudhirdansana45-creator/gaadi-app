import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/status_chip.dart';
import '../../models/mock_models.dart';
import '../../services/api_service.dart';

class ReturnFinalBillScreen extends StatefulWidget {
  final Booking? booking;
  final String? bookingId;
  final VoidCallback onBillSettled;
  final VoidCallback onCancel;

  const ReturnFinalBillScreen({
    super.key,
    this.booking,
    this.bookingId,
    required this.onBillSettled,
    required this.onCancel,
  });

  @override
  State<ReturnFinalBillScreen> createState() => _ReturnFinalBillScreenState();
}

class _ReturnFinalBillScreenState extends State<ReturnFinalBillScreen> {
  final _endOdometerController = TextEditingController();
  final _damageAmountController = TextEditingController(text: '0');
  final _extraKmChargeController = TextEditingController(text: '0');

  Booking? _booking;
  bool _isLoadingBooking = false;
  bool _isDamaged = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    if (_booking == null && widget.bookingId != null) {
      _fetchBooking();
    }
  }

  Future<void> _fetchBooking() async {
    setState(() => _isLoadingBooking = true);
    try {
      final res = await ApiService().getBookingDetail(widget.bookingId!);
      if (res != null && res['data'] != null && mounted) {
        setState(() {
          _booking = Booking.fromJson(res['data'] as Map<String, dynamic>);
        });
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoadingBooking = false);
    }
  }

  @override
  void dispose() {
    _endOdometerController.dispose();
    _damageAmountController.dispose();
    _extraKmChargeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingBooking) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Return Vehicle & Final Bill'),
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
          title: const Text('Return Vehicle & Final Bill'),
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
    final startKm = currentBooking.startOdometer;
    final endKm = int.tryParse(_endOdometerController.text.trim()) ?? startKm;
    final totalRunKm = (endKm - startKm).clamp(0, 999999);

    final double damageCharge = _isDamaged ? (double.tryParse(_damageAmountController.text.trim()) ?? 0.0) : 0.0;
    final double extraKmCharge = double.tryParse(_extraKmChargeController.text.trim()) ?? 0.0;
    
    // Dynamic late fee calculation
    final now = DateTime.now();
    final isOverdue = now.isAfter(currentBooking.endDate);
    final hoursLate = isOverdue ? now.difference(currentBooking.endDate).inHours : 0;
    final double lateFee = hoursLate > 0 ? (hoursLate * 200.0) : 0.0;

    final securityDeposit = currentBooking.securityDeposit;
    final pendingRent = currentBooking.pendingAmount;
    final totalDeductions = pendingRent + extraKmCharge + lateFee + damageCharge;
    final netRefundToCustomer = securityDeposit - totalDeductions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Return ${currentBooking.id} & Final Bill'),
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
              // Return Status Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isOverdue ? AppColors.criticalBg : AppColors.successBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isOverdue ? AppColors.criticalBorder : AppColors.successBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isOverdue ? Icons.history_toggle_off_rounded : Icons.check_circle_rounded,
                          color: isOverdue ? AppColors.criticalRed : AppColors.successGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Trip Return Status:',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (isOverdue && hoursLate > 0)
                      StatusChip.overdue(label: 'Late by $hoursLate Hours')
                    else
                      const Text(
                        'On-Time Return',
                        style: TextStyle(color: AppColors.successGreen, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

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
                    // 1. Odometer Check
                    const Text('1. Return Telemetry & Odometer Check', style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.canvasLow, borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Start Odometer', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                Text('$startKm KM', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'End Odometer (KM)',
                            hintText: 'e.g. ${startKm + 150}',
                            controller: _endOdometerController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.canvasLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Distance Travelled:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Text('$totalRunKm KM', style: const TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.borderHairline),
                    const SizedBox(height: 16),

                    // 2. Extra Charges & Damages
                    const Text('2. Additional Charges & Deductions', style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Extra KM / Fuel Surcharge (₹)',
                      hintText: '0',
                      controller: _extraKmChargeController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),

                    CheckboxListTile(
                      value: _isDamaged,
                      onChanged: (val) => setState(() => _isDamaged = val ?? false),
                      title: const Text('Report New Damage / Penalties', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Deduct repair estimates directly from held security deposit', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      activeColor: AppColors.criticalRed,
                      contentPadding: EdgeInsets.zero,
                    ),

                    if (_isDamaged) ...[
                      const SizedBox(height: 10),
                      CustomTextField(
                        label: 'Damage Deduction Amount (₹)',
                        hintText: '0',
                        controller: _damageAmountController,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.car_crash_rounded,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.borderHairline),
                    const SizedBox(height: 16),

                    // 3. Settlement Breakdown
                    const Text('3. Settlement & Refund Math Breakdown', style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    _mathRow('Held Security Deposit', '₹${securityDeposit.toInt()}', isPositive: true),
                    _mathRow('Pending Trip Rental Balance', '- ₹${pendingRent.toInt()}', isPositive: false),
                    if (extraKmCharge > 0)
                      _mathRow('Extra KM / Fuel Charges', '- ₹${extraKmCharge.toInt()}', isPositive: false),
                    if (lateFee > 0)
                      _mathRow('Late Fee ($hoursLate h Overdue)', '- ₹${lateFee.toInt()}', isPositive: false),
                    if (_isDamaged && damageCharge > 0)
                      _mathRow('Vehicle Damage Recovery', '- ₹${damageCharge.toInt()}', isPositive: false),

                    const Divider(color: AppColors.borderHairline),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          netRefundToCustomer >= 0 ? 'Net Refundable to Customer:' : 'Net Receivable from Customer:',
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '₹${netRefundToCustomer.abs().toInt()}',
                          style: TextStyle(
                            color: netRefundToCustomer >= 0 ? AppColors.successGreen : AppColors.criticalRed,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    CustomButton(
                      text: 'Settle Bill & Close Booking',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: _isLoading,
                      onPressed: () async {
                        final endReading = int.tryParse(_endOdometerController.text.trim());
                        if (endReading == null || endReading < startKm) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please enter an end odometer reading of at least $startKm KM'),
                              backgroundColor: AppColors.criticalRed,
                            ),
                          );
                          return;
                        }

                        setState(() => _isLoading = true);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await ApiService().returnSettlement(
                            currentBooking.id,
                            endOdometer: endReading,
                            extraKmCharge: extraKmCharge,
                            fuelCharge: 0.0,
                            damageDeduction: damageCharge,
                            finalSettlementAmount: netRefundToCustomer.abs(),
                            paymentMode: 'Cash',
                          );
                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Return settlement completed successfully!'),
                                backgroundColor: AppColors.successGreen,
                              ),
                            );
                            widget.onBillSettled();
                          }
                        } catch (e) {
                          final msg = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: AppColors.criticalRed,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isLoading = false);
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

  Widget _mathRow(String title, String amount, {required bool isPositive}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(
            amount,
            style: TextStyle(
              color: isPositive ? AppColors.successGreen : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
