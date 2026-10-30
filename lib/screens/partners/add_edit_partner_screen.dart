import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/info_note.dart';
import '../../models/mock_models.dart';
import '../../services/api_service.dart';

class AddEditPartnerScreen extends StatefulWidget {
  final Partner? partner;
  final String? partnerId;
  final VoidCallback onSaved;
  final VoidCallback onCancel;

  const AddEditPartnerScreen({
    super.key,
    this.partner,
    this.partnerId,
    required this.onSaved,
    required this.onCancel,
  });

  @override
  State<AddEditPartnerScreen> createState() => _AddEditPartnerScreenState();
}

class _AddEditPartnerScreenState extends State<AddEditPartnerScreen> {
  Partner? _partner;
  bool _isFetching = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _splitCtrl;
  late TextEditingController _fixedAmtCtrl;
  late TextEditingController _bankCtrl;
  late TextEditingController _upiCtrl;

  String _payoutType = 'percentage'; // 'percentage' or 'fixed'
  String _fixedFrequency = 'Per Month'; // 'Per Day', 'Per Week', 'Per Month'
  late Set<String> _selectedVehicleIds;
  bool _isLoading = false;
  List<Vehicle> _availableVehicles = [];
  bool _isLoadingVehicles = false;

  final List<String> _frequencyOptions = ['Per Day', 'Per Week', 'Per Month'];

  @override
  void initState() {
    super.initState();
    _partner = widget.partner;
    _initControllers();
    _fetchVehicles();
    if (_partner == null && widget.partnerId != null && widget.partnerId!.isNotEmpty) {
      _fetchPartner();
    }
  }

  Future<void> _fetchVehicles() async {
    setState(() => _isLoadingVehicles = true);
    try {
      final res = await ApiService().getVehicles();
      if (res != null && res['data'] is List && mounted) {
        setState(() {
          _availableVehicles = (res['data'] as List)
              .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingVehicles = false);
  }

  void _initControllers() {
    _nameCtrl = TextEditingController(text: _partner?.name ?? '');
    _phoneCtrl = TextEditingController(text: _partner?.phone.replaceAll('+91 ', '') ?? '');
    _emailCtrl = TextEditingController(text: _partner?.email ?? '');
    _splitCtrl = TextEditingController(text: _partner?.profitSplitPercent.toInt().toString() ?? '70');
    _fixedAmtCtrl = TextEditingController(
        text: _partner?.fixedPayoutAmount != null && _partner!.fixedPayoutAmount > 0
            ? _partner!.fixedPayoutAmount.toInt().toString()
            : '15000');
    _bankCtrl = TextEditingController(text: _partner?.bankAccount ?? '');
    _upiCtrl = TextEditingController(text: _partner?.upiId ?? '');

    _payoutType = _partner?.payoutType ?? 'percentage';
    _fixedFrequency = _partner?.fixedPayoutFrequency ?? 'Per Month';
    _selectedVehicleIds = Set<String>.from(_partner?.assignedVehicleIds ?? []);
  }

  Future<void> _fetchPartner() async {
    setState(() => _isFetching = true);
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
            _nameCtrl.text = match.name;
            _phoneCtrl.text = match.phone.replaceAll('+91 ', '');
            _emailCtrl.text = match.email;
            _splitCtrl.text = match.profitSplitPercent.toInt().toString();
            _fixedAmtCtrl.text = match.fixedPayoutAmount.toInt().toString();
            _bankCtrl.text = match.bankAccount;
            _upiCtrl.text = match.upiId;
            _payoutType = match.payoutType;
            _fixedFrequency = match.fixedPayoutFrequency;
            _selectedVehicleIds = Set<String>.from(match.assignedVehicleIds);
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isFetching = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _splitCtrl.dispose();
    _fixedAmtCtrl.dispose();
    _bankCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter partner name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    final payload = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'mobile': _phoneCtrl.text.trim(),
      'share_type': _payoutType,
      'share_value': _payoutType == 'percentage'
          ? (double.tryParse(_splitCtrl.text) ?? 70.0)
          : (double.tryParse(_fixedAmtCtrl.text) ?? 15000.0),
    };

    try {
      if (_partner == null) {
        await ApiService().createPartner(payload);
      } else {
        await ApiService().updatePartner(_partner!.id, payload);
      }
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(_partner == null ? 'Partner added successfully!' : 'Partner details saved!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        widget.onSaved();
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
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Edit Fleet Partner'),
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

    if (widget.partnerId != null && _partner == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Edit Fleet Partner'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: widget.onCancel,
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
                  'The partner you are trying to edit does not exist or has been removed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Back to Fleet Partners',
                  variant: ButtonVariant.secondary,
                  onPressed: widget.onCancel,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isEdit = _partner != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(!isEdit ? 'Add Fleet Partner' : 'Edit Fleet Partner'),
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
                    Text(
                      !isEdit ? 'Add New Fleet Partner' : 'Edit Partner Details',
                      style: const TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: widget.onCancel,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Full Name',
                  hintText: 'e.g. Suresh Kumar',
                  controller: _nameCtrl,
                  prefixIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Mobile Number',
                        hintText: '9810011223',
                        controller: _phoneCtrl,
                        prefixText: '+91 ',
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Email Address',
                        hintText: 'partner@gmail.com',
                        controller: _emailCtrl,
                        prefixIcon: Icons.email_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.borderHairline),
                const SizedBox(height: 16),

                // Assigned Vehicles Multi-Select Section
                const Text(
                  'Assigned Fleet Vehicles',
                  style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select vehicles co-owned or attached by this partner:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),

                if (_isLoadingVehicles)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primaryCyan, strokeWidth: 2)),
                  )
                else if (_availableVehicles.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.canvasLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: const Text(
                      'No vehicles found in fleet to assign.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableVehicles.map((v) {
                      final isSelected = _selectedVehicleIds.contains(v.id);
                      return FilterChip(
                        selected: isSelected,
                        label: Text('${v.name} (${v.regNumber})'),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedVehicleIds.add(v.id);
                            } else {
                              _selectedVehicleIds.remove(v.id);
                            }
                          });
                        },
                        selectedColor: AppColors.primaryCyan.withValues(alpha: 0.2),
                        backgroundColor: AppColors.canvasLow,
                        checkmarkColor: AppColors.primaryCyan,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primaryCyan : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? AppColors.primaryCyan : AppColors.borderSubtle,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.borderHairline),
                const SizedBox(height: 16),

                // Payout Model: Percentage vs Fixed Toggle
                const Text(
                  'Profit Sharing & Payout Model',
                  style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.canvasLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _payoutType = 'percentage'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _payoutType == 'percentage'
                                  ? AppColors.primaryCyan.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _payoutType == 'percentage'
                                    ? AppColors.primaryCyan
                                    : Colors.transparent,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Percentage Split (%)',
                              style: TextStyle(
                                color: _payoutType == 'percentage'
                                    ? AppColors.primaryCyan
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _payoutType = 'fixed'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _payoutType == 'fixed'
                                  ? AppColors.primaryCyan.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _payoutType == 'fixed'
                                    ? AppColors.primaryCyan
                                    : Colors.transparent,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Fixed Amount (₹)',
                              style: TextStyle(
                                color: _payoutType == 'fixed'
                                    ? AppColors.primaryCyan
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                if (_payoutType == 'percentage') ...[
                  CustomTextField(
                    label: 'Profit Sharing Split (%)',
                    hintText: '70',
                    controller: _splitCtrl,
                    suffixIcon: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                        '%',
                        style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  const InfoNote(
                    text: 'Percentage is calculated on vehicle rent only. Deposit, late fee, extra km, damage, challan and GST are excluded.',
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Fixed Payout Amount (₹)',
                          hintText: '15000',
                          controller: _fixedAmtCtrl,
                          prefixText: '₹ ',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payout Frequency',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _fixedFrequency,
                              dropdownColor: AppColors.surfaceCard,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.canvasLow,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                                ),
                              ),
                              items: _frequencyOptions.map((f) {
                                return DropdownMenuItem(value: f, child: Text(f));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _fixedFrequency = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),
                const Divider(color: AppColors.borderHairline),
                const SizedBox(height: 16),

                // Optional Bank & UPI Settlement Section
                const Text(
                  'Bank & UPI Settlement Details (Optional)',
                  style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Bank Account Number / IFSC (Optional)',
                  hintText: 'HDFC Bank - 501002910291',
                  controller: _bankCtrl,
                  prefixIcon: Icons.account_balance_rounded,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'UPI VPA ID (Optional)',
                  hintText: 'suresh@upi',
                  controller: _upiCtrl,
                  prefixIcon: Icons.qr_code_rounded,
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: widget.partner == null ? 'Save Partner Record' : 'Update Partner Record',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: _isLoading,
                  onPressed: _handleSave,
                ),
              ],
            ),
          ),
          const SizedBox(height: 110), // Gap to prevent overlap with bottom tab menu
        ],
      ),
    ),
  ),
);
  }
}
