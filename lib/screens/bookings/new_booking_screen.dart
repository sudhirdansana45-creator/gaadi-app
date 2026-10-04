import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/counter_chip.dart';
import '../../data/mock_data.dart';
import '../../data/dummy_plan_data.dart';
import '../../models/mock_models.dart';

class NewBookingScreen extends StatefulWidget {
  final Vehicle? preselectedVehicle;
  final VoidCallback onBookingCreated;
  final VoidCallback onCancel;

  const NewBookingScreen({
    super.key,
    this.preselectedVehicle,
    required this.onBookingCreated,
    required this.onCancel,
  });

  @override
  State<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends State<NewBookingScreen> {
  late Vehicle _selectedVehicle;
  late Customer _selectedCustomer;

  bool _isHourlyRate = false;
  int _rentalDuration = 2; // Days or Hours depending on _isHourlyRate
  double _advancePaid = 2000.0;
  final String _paymentMode = 'UPI (GPay)';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Pick preselected or first non-disabled vehicle
    final availableList = MockData.vehicles.where((v) => v.status != VehicleStatus.disabled).toList();
    if (widget.preselectedVehicle != null && widget.preselectedVehicle!.status != VehicleStatus.disabled) {
      _selectedVehicle = widget.preselectedVehicle!;
    } else if (availableList.isNotEmpty) {
      _selectedVehicle = availableList.first;
    } else {
      _selectedVehicle = MockData.vehicles.first;
    }

    _selectedCustomer = MockData.customers.first;
  }

  @override
  Widget build(BuildContext context) {
    final double unitRate = _isHourlyRate ? _selectedVehicle.hourlyRate : _selectedVehicle.dailyRate;
    final double totalRent = unitRate * _rentalDuration;
    final double securityDeposit = _selectedVehicle.securityDeposit;
    final double totalPayable = totalRent + securityDeposit;
    final double remainingBalance = totalPayable - _advancePaid;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quota & Billing Counter Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long_rounded, color: AppColors.primaryCyan, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Daily Bill Quota:',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                CounterChip(
                  count: DummyPlanData().usage.billsUsedToday,
                  limit: DummyPlanData().usage.dailyBillLimit,
                  label: 'bills used today',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 1. Vehicle Selector with Disabled Locks
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. Select Vehicle from Fleet',
                  style: TextStyle(color: AppColors.primaryCyan, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Vehicle>(
                  initialValue: _selectedVehicle,
                  dropdownColor: AppColors.surfaceHover,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.canvasLow,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: MockData.vehicles.map((v) {
                    final bool isDisabled = v.status == VehicleStatus.disabled;
                    return DropdownMenuItem<Vehicle>(
                      value: v,
                      enabled: !isDisabled, // Disable selection if disabled
                      child: Row(
                        children: [
                          if (isDisabled) ...[
                            const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 16),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            '${v.name} (${v.regNumber}) - ₹${v.dailyRate.toInt()}/day',
                            style: TextStyle(
                              color: isDisabled ? AppColors.textMuted : AppColors.textPrimary,
                              decoration: isDisabled ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (isDisabled) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.canvasLow,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: const Text(
                                'DISABLED',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null && val.status != VehicleStatus.disabled) {
                      setState(() => _selectedVehicle = val);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Customer Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '2. Customer / Renter Profile',
                  style: TextStyle(color: AppColors.primaryCyan, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Customer>(
                  initialValue: _selectedCustomer,
                  dropdownColor: AppColors.surfaceHover,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.canvasLow,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: MockData.customers.map((c) {
                    return DropdownMenuItem<Customer>(
                      value: c,
                      child: Text('${c.name} (${c.phone})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCustomer = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Rate Type Toggle & Duration Math
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '3. Rate Model & Duration Math',
                      style: TextStyle(color: AppColors.primaryCyan, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    // Hourly vs Daily Toggle
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.canvasLow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          _rateToggleBtn('Daily', !_isHourlyRate, () {
                            setState(() {
                              _isHourlyRate = false;
                              _rentalDuration = 2; // Default 2 days
                            });
                          }),
                          _rateToggleBtn('Hourly', _isHourlyRate, () {
                            setState(() {
                              _isHourlyRate = true;
                              _rentalDuration = 6; // Default 6 hours
                            });
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Duration Stepper
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isHourlyRate ? 'Rental Hours:' : 'Rental Days:',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.primaryCyan),
                          onPressed: _rentalDuration > 1 ? () => setState(() => _rentalDuration--) : null,
                        ),
                        Text(
                          '$_rentalDuration ${_isHourlyRate ? "Hours" : "Days"}',
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryCyan),
                          onPressed: () => setState(() => _rentalDuration++),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.borderHairline),
                const SizedBox(height: 12),

                // Summary Row Updates
                _buildSummaryRow(
                  'Base Rental Charges ($_rentalDuration ${_isHourlyRate ? "hrs" : "days"} @ ₹${unitRate.toInt()}/${_isHourlyRate ? "hr" : "day"})',
                  '₹${totalRent.toInt()}',
                ),
                _buildSummaryRow('Refundable Security Deposit', '₹${securityDeposit.toInt()}'),
                const SizedBox(height: 8),
                const Divider(color: AppColors.borderHairline),
                const SizedBox(height: 8),
                _buildSummaryRow('Total Amount', '₹${totalPayable.toInt()}', isBold: true),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Advance Payment Received ($_paymentMode)',
                  hintText: '2000',
                  prefixText: '₹',
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    final p = double.tryParse(val);
                    if (p != null) setState(() => _advancePaid = p);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Remaining Balance Due at Return:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    Text(
                      '₹${remainingBalance.toInt()}',
                      style: const TextStyle(color: AppColors.warningAmber, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          CustomButton(
            text: 'Confirm & Generate Booking',
            icon: Icons.check_circle_outline_rounded,
            isLoading: _isLoading,
            onPressed: () {
              setState(() => _isLoading = true);
              Future.delayed(const Duration(milliseconds: 600), () {
                if (mounted) {
                  setState(() => _isLoading = false);
                  widget.onBookingCreated();
                }
              });
            },
          ),
          const SizedBox(height: 110), // Gap to prevent overlap with bottom tab menu
        ],
      ),
    );
  }

  Widget _rateToggleBtn(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryCyan : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.textDark : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: isBold ? 15 : 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          Text(
            val,
            style: TextStyle(
              color: isBold ? AppColors.primaryCyan : AppColors.textPrimary,
              fontSize: isBold ? 18 : 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
