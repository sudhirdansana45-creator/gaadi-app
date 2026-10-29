import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/counter_chip.dart';
import '../../data/mock_data.dart';
import '../../models/mock_models.dart';
import '../../services/api_service.dart';

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
  List<Vehicle> _fleetVehicles = [];
  List<Customer> _existingCustomers = [];
  Vehicle? _selectedVehicle;

  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _advancePaidCtrl = TextEditingController(text: '2000');

  bool _isHourlyRate = false;
  int _rentalDuration = 2; // Days or Hours depending on _isHourlyRate
  double _advancePaid = 2000.0;
  String _paymentMode = 'UPI (GPay / PhonePe)';
  
  bool _isLoading = false;
  bool _isLoadingData = true;
  int _billsToday = 0;
  int _dailyLimit = 10;

  final List<String> _paymentModes = [
    'UPI (GPay / PhonePe)',
    'Cash in Hand',
    'Credit / Debit Card',
    'Bank Transfer (NEFT/IMPS)',
  ];

  @override
  void initState() {
    super.initState();
    _advancePaidCtrl.addListener(() {
      final p = double.tryParse(_advancePaidCtrl.text.trim());
      if (p != null && mounted) {
        setState(() => _advancePaid = p);
      }
    });
    _fetchInitialData();
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _advancePaidCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoadingData = true);
    try {
      // 1. Fetch Fleet Vehicles from API
      try {
        final vRes = await ApiService().getVehicles();
        if (vRes != null && vRes['data'] is List) {
          final list = (vRes['data'] as List)
              .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
              .toList();
          if (list.isNotEmpty) {
            _fleetVehicles = list;
          }
        }
      } catch (_) {}

      // Fallback vehicles if API returned empty or offline
      if (_fleetVehicles.isEmpty) {
        _fleetVehicles = List.from(MockData.vehicles);
      }

      // 2. Determine initial selected vehicle
      if (widget.preselectedVehicle != null) {
        final match = _fleetVehicles.firstWhere(
          (v) => v.id == widget.preselectedVehicle!.id,
          orElse: () => widget.preselectedVehicle!,
        );
        _selectedVehicle = match;
      } else {
        final available = _fleetVehicles.where((v) => v.status != VehicleStatus.disabled).toList();
        _selectedVehicle = available.isNotEmpty ? available.first : _fleetVehicles.first;
      }

      // 3. Fetch Existing Customers from API
      try {
        final cRes = await ApiService().getCustomers();
        if (cRes != null && cRes['data'] is List) {
          final cList = (cRes['data'] as List)
              .map((item) => Customer.fromJson(item as Map<String, dynamic>))
              .toList();
          if (cList.isNotEmpty) {
            _existingCustomers = cList;
          }
        }
      } catch (_) {}

      if (_existingCustomers.isEmpty) {
        _existingCustomers = List.from(MockData.customers);
      }

      // Default customer fields from first customer
      if (_existingCustomers.isNotEmpty && _customerNameCtrl.text.isEmpty) {
        _customerNameCtrl.text = _existingCustomers.first.name;
        _customerPhoneCtrl.text = _existingCustomers.first.phone.replaceAll('+91 ', '');
      }

      // 4. Fetch Quota Info
      try {
        final statsRes = await ApiService().getDashboardStats();
        if (statsRes != null && statsRes['data'] != null && statsRes['data']['quota'] != null) {
          final q = statsRes['data']['quota'];
          _billsToday = (q['bills_today'] as num?)?.toInt() ?? 0;
          _dailyLimit = (q['bills_per_day'] as num?)?.toInt() ?? 10;
        }
      } catch (_) {}
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  void _onCustomerSelected(Customer c) {
    setState(() {
      _customerNameCtrl.text = c.name;
      _customerPhoneCtrl.text = c.phone.replaceAll('+91 ', '');
    });
  }

  Future<void> _handleCreateBooking() async {
    final name = _customerNameCtrl.text.trim();
    final phone = _customerPhoneCtrl.text.trim();

    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle from your fleet'), backgroundColor: AppColors.criticalRed),
      );
      return;
    }

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter customer full name'), backgroundColor: AppColors.criticalRed),
      );
      return;
    }

    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number'), backgroundColor: AppColors.criticalRed),
      );
      return;
    }

    setState(() => _isLoading = true);

    final double unitRate = _isHourlyRate ? _selectedVehicle!.hourlyRate : _selectedVehicle!.dailyRate;
    final double totalRent = unitRate * _rentalDuration;
    final double securityDeposit = _selectedVehicle!.securityDeposit;
    final double totalPayable = totalRent + securityDeposit;
    final double remainingBalance = (totalPayable - _advancePaid).clamp(0.0, 999999.0);

    final now = DateTime.now();
    final endAt = _isHourlyRate
        ? now.add(Duration(hours: _rentalDuration))
        : now.add(Duration(days: _rentalDuration));

    final messenger = ScaffoldMessenger.of(context);

    try {
      final res = await ApiService().createBooking({
        'vehicle_id': _selectedVehicle!.id,
        'customer_name': name,
        'customer_mobile': phone.startsWith('+91') ? phone : '+91 $phone',
        'start_at': now.toIso8601String(),
        'end_at': endAt.toIso8601String(),
        'amount': totalRent,
        'advance_paid': _advancePaid,
        'security_deposit': securityDeposit,
        'payment_mode': _paymentMode,
      });

      if (res != null && res['data'] != null) {
        final newBooking = Booking.fromJson(res['data'] as Map<String, dynamic>);
        MockData.bookings.insert(0, newBooking);
      } else {
        _insertLocalBooking(name, phone, totalPayable, remainingBalance, securityDeposit);
      }

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Booking generated successfully! Fleet status updated.'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        widget.onBookingCreated();
      }
    } catch (e) {
      // If error occurred (such as daily limit reached or vehicle conflict), display exact server message
      final msg = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.criticalRed,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _insertLocalBooking(String name, String phone, double totalPayable, double remainingBalance, double securityDeposit) {
    MockData.bookings.insert(
      0,
      Booking(
        id: 'BK-${DateTime.now().millisecondsSinceEpoch % 10000}',
        customerName: name,
        customerPhone: phone.startsWith('+91') ? phone : '+91 $phone',
        vehicleName: _selectedVehicle?.name ?? 'Vehicle',
        vehicleRegNumber: _selectedVehicle?.regNumber ?? 'DL 01 AB 1234',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: _rentalDuration)),
        totalAmount: totalPayable,
        advancePaid: _advancePaid,
        pendingAmount: remainingBalance,
        securityDeposit: securityDeposit,
        status: BookingStatus.active,
        startOdometer: _selectedVehicle?.odometerKm ?? 0,
        paymentMode: _paymentMode,
        kycDocType: 'Aadhaar Card',
        kycDocNumber: 'Verified',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double unitRate = _selectedVehicle != null
        ? (_isHourlyRate ? _selectedVehicle!.hourlyRate : _selectedVehicle!.dailyRate)
        : 2000.0;
    final double totalRent = unitRate * _rentalDuration;
    final double securityDeposit = _selectedVehicle?.securityDeposit ?? 3000.0;
    final double totalPayable = totalRent + securityDeposit;
    final double remainingBalance = (totalPayable - _advancePaid).clamp(0.0, 999999.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create New Booking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onCancel,
        ),
      ),
      body: SafeArea(
        top: false,
        child: _isLoadingData
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryCyan),
              )
            : SingleChildScrollView(
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
                            count: _billsToday,
                            limit: _dailyLimit,
                            label: 'bills used today',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 1. Vehicle Selector with Status Badges
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
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '1. Select Vehicle from Fleet',
                                style: TextStyle(color: AppColors.primaryCyan, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Fleet Live',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_fleetVehicles.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.canvasLow,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'No vehicles found in fleet. Please add a vehicle first.',
                                style: TextStyle(color: AppColors.warningAmber, fontSize: 13),
                              ),
                            )
                          else
                            DropdownButtonFormField<Vehicle>(
                              initialValue: _selectedVehicle,
                              dropdownColor: AppColors.surfaceHover,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.canvasLow,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _fleetVehicles.map((v) {
                                final bool isDisabled = v.status == VehicleStatus.disabled;
                                return DropdownMenuItem<Vehicle>(
                                  value: v,
                                  enabled: !isDisabled,
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

                    // 2. Customer / Renter Profile Inputs
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
                                '2. Customer / Renter Details',
                                style: TextStyle(color: AppColors.primaryCyan, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              if (_existingCustomers.isNotEmpty)
                                PopupMenuButton<Customer>(
                                  color: AppColors.surfaceHover,
                                  icon: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.history_rounded, color: AppColors.primaryCyan, size: 16),
                                      SizedBox(width: 4),
                                      Text('Pick Past Customer', style: TextStyle(color: AppColors.primaryCyan, fontSize: 11, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  onSelected: _onCustomerSelected,
                                  itemBuilder: (ctx) => _existingCustomers.map((c) {
                                    return PopupMenuItem<Customer>(
                                      value: c,
                                      child: Text('${c.name} (${c.phone})', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: 'Customer Full Name *',
                            hintText: 'e.g. Rahul Sharma',
                            controller: _customerNameCtrl,
                            prefixIcon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: 'Customer Mobile Number *',
                            hintText: '9876543210',
                            controller: _customerPhoneCtrl,
                            prefixText: '+91 ',
                            prefixIcon: Icons.phone_android_rounded,
                            keyboardType: TextInputType.phone,
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
                                '3. Rental Tariff & Duration',
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

                          // Summary Calculation
                          _buildSummaryRow(
                            'Rental Tariff ($_rentalDuration ${_isHourlyRate ? "hrs" : "days"} @ ₹${unitRate.toInt()}/${_isHourlyRate ? "hr" : "day"})',
                            '₹${totalRent.toInt()}',
                          ),
                          _buildSummaryRow('Refundable Security Deposit', '₹${securityDeposit.toInt()}'),
                          const SizedBox(height: 8),
                          const Divider(color: AppColors.borderHairline),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Total Amount', '₹${totalPayable.toInt()}', isBold: true),
                          const SizedBox(height: 16),

                          // Payment Mode Selector
                          const Text('Payment Mode Received', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _paymentMode,
                            dropdownColor: AppColors.surfaceHover,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.canvasLow,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: _paymentModes.map((mode) {
                              return DropdownMenuItem<String>(
                                value: mode,
                                child: Text(mode),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _paymentMode = val);
                            },
                          ),
                          const SizedBox(height: 14),

                          CustomTextField(
                            label: 'Advance Payment Received',
                            hintText: '2000',
                            controller: _advancePaidCtrl,
                            prefixText: '₹',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Remaining Due at Return:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
                      onPressed: _handleCreateBooking,
                    ),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
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
