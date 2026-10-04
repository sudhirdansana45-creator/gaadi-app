import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/status_chip.dart';
import '../../models/mock_models.dart';

class ReturnFinalBillScreen extends StatefulWidget {
  final Booking? booking;
  final VoidCallback onBillSettled;
  final VoidCallback onCancel;

  const ReturnFinalBillScreen({
    super.key,
    this.booking,
    required this.onBillSettled,
    required this.onCancel,
  });

  @override
  State<ReturnFinalBillScreen> createState() => _ReturnFinalBillScreenState();
}

class _ReturnFinalBillScreenState extends State<ReturnFinalBillScreen> {
  final _endOdometerController = TextEditingController(text: '24850');
  final _damageAmountController = TextEditingController(text: '1500');

  bool _isDamaged = true;
  final double _extraKmCharge = 600.0;
  final double _lateFee = 800.0;
  bool _isLoading = false;

  @override
  void dispose() {
    _endOdometerController.dispose();
    _damageAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startKm = widget.booking?.startOdometer ?? 24200;
    final endKm = int.tryParse(_endOdometerController.text) ?? 24850;
    final totalRunKm = (endKm - startKm).clamp(0, 999999);

    final double damageCharge = _isDamaged ? (double.tryParse(_damageAmountController.text) ?? 0.0) : 0.0;
    final securityDeposit = widget.booking?.securityDeposit ?? 5000.0;
    final pendingRent = widget.booking?.pendingAmount ?? 7000.0;
    final totalDeductions = pendingRent + _extraKmCharge + _lateFee + damageCharge;
    final netRefundToCustomer = securityDeposit - totalDeductions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overdue Return Status Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.criticalBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.criticalBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_toggle_off_rounded, color: AppColors.criticalRed, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Trip Return Status:',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                StatusChip.overdue(label: 'Late by 3.5 Hours'),
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
                        hintText: '24850',
                        controller: _endOdometerController,
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHover,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Driven Distance in Trip:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text('$totalRunKm KM', style: const TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.borderHairline),
                const SizedBox(height: 16),

                // 2. Return Damage Inspection Card
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('2. Return Damage & Penalty Inspection', style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 14)),
                    Switch(
                      value: _isDamaged,
                      activeColor: AppColors.warningAmber,
                      onChanged: (val) => setState(() => _isDamaged = val),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_isDamaged) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.warningBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.car_repair_rounded, color: AppColors.warningAmber, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'New Scratch / Damage Detected',
                              style: TextStyle(color: AppColors.warningAmber, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Damage Fine / Repair Estimate (₹)',
                          hintText: '1500',
                          controller: _damageAmountController,
                          prefixText: '₹',
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Divider(color: AppColors.borderHairline),
                const SizedBox(height: 16),

                // 3. Billing Breakdown
                const Text('3. Settlement & Refund Math Breakdown', style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                _mathRow('Held Security Deposit', '₹${securityDeposit.toInt()}', isPositive: true),
                _mathRow('Pending Trip Rental Balance', '- ₹${pendingRent.toInt()}', isPositive: false),
                _mathRow('Extra KM / Fuel Charges', '- ₹${_extraKmCharge.toInt()}', isPositive: false),
                _mathRow('Late Fee (3.5h Overdue)', '- ₹${_lateFee.toInt()}', isPositive: false),
                if (_isDamaged)
                  _mathRow('New Vehicle Damage Recovery', '- ₹${damageCharge.toInt()}', isPositive: false),

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
                  onPressed: () {
                    setState(() => _isLoading = true);
                    Future.delayed(const Duration(milliseconds: 600), () {
                      if (mounted) {
                        setState(() => _isLoading = false);
                        widget.onBillSettled();
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 110), // Gap to prevent overlap with bottom tab menu
        ],
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
          Text(amount, style: TextStyle(color: isPositive ? AppColors.successGreen : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
