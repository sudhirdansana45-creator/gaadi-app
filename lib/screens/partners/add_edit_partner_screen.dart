import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/info_note.dart';
import '../../models/mock_models.dart';
import '../../data/mock_data.dart';
import '../../services/api_service.dart';

class AddEditPartnerScreen extends StatefulWidget {
  final Partner? partner;
  final VoidCallback onSaved;
  final VoidCallback onCancel;

  const AddEditPartnerScreen({
    super.key,
    this.partner,
    required this.onSaved,
    required this.onCancel,
  });

  @override
  State<AddEditPartnerScreen> createState() => _AddEditPartnerScreenState();
}

class _AddEditPartnerScreenState extends State<AddEditPartnerScreen> {
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

  final List<String> _frequencyOptions = ['Per Day', 'Per Week', 'Per Month'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.partner?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.partner?.phone.replaceAll('+91 ', '') ?? '');
    _emailCtrl = TextEditingController(text: widget.partner?.email ?? '');
    _splitCtrl = TextEditingController(text: widget.partner?.profitSplitPercent.toInt().toString() ?? '70');
    _fixedAmtCtrl = TextEditingController(
        text: widget.partner?.fixedPayoutAmount != null && widget.partner!.fixedPayoutAmount > 0
            ? widget.partner!.fixedPayoutAmount.toInt().toString()
            : '15000');
    _bankCtrl = TextEditingController(text: widget.partner?.bankAccount ?? '');
    _upiCtrl = TextEditingController(text: widget.partner?.upiId ?? '');

    _payoutType = widget.partner?.payoutType ?? 'percentage';
    _fixedFrequency = widget.partner?.fixedPayoutFrequency ?? 'Per Month';
    _selectedVehicleIds = Set<String>.from(widget.partner?.assignedVehicleIds ?? ['V001', 'V005']);
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
      if (widget.partner == null) {
        await ApiService().createPartner(payload);
      } else {
        await ApiService().updatePartner(widget.partner!.id, payload);
      }
    } catch (e) {
      // Offline fallback
      if (widget.partner == null) {
        MockData.partners.add(
          Partner(
            id: 'P${DateTime.now().millisecondsSinceEpoch}',
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            profitSplitPercent: double.tryParse(_splitCtrl.text) ?? 70,
            assignedVehicleIds: _selectedVehicleIds.toList(),
            payoutType: _payoutType,
            fixedPayoutAmount: double.tryParse(_fixedAmtCtrl.text) ?? 0,
            fixedPayoutFrequency: _fixedFrequency,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        widget.onSaved();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                      widget.partner == null ? 'Add New Fleet Partner' : 'Edit Partner Details',
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

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MockData.vehicles.map((v) {
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
    );
  }
}
