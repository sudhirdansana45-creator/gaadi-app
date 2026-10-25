import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/counter_chip.dart';
import '../../widgets/info_note.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../services/api_service.dart';

class UsersAndRolesScreen extends StatefulWidget {
  final VoidCallback onBack;

  const UsersAndRolesScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<UsersAndRolesScreen> createState() => _UsersAndRolesScreenState();
}

class _UsersAndRolesScreenState extends State<UsersAndRolesScreen> {
  // Local staff list state for demo toggle
  late List<_StaffModel> _staffList;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _staffList = [
      _StaffModel(
        id: 'USR-01',
        name: 'Rajesh Sharma',
        phone: '+91 98188 00112',
        role: 'Admin',
        isActive: true,
        isDisabledByPlan: false,
      ),
      _StaffModel(
        id: 'USR-02',
        name: 'Anil Kumar',
        phone: '+91 98733 44556',
        role: 'Manager',
        isActive: true,
        isDisabledByPlan: false,
      ),
      _StaffModel(
        id: 'USR-03',
        name: 'Manoj Singh',
        phone: '+91 99100 88990',
        role: 'Staff',
        isActive: false,
        isDisabledByPlan: true,
      ),
    ];
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getStaffUsers();
      if (res != null && res['data'] is List && mounted) {
        final List list = res['data'];
        if (list.isNotEmpty) {
          final mapped = list.map((s) {
            return _StaffModel(
              id: s['id']?.toString() ?? '',
              name: s['name']?.toString() ?? '',
              phone: s['mobile']?.toString() ?? s['phone']?.toString() ?? '',
              role: (s['role']?.toString() ?? 'Staff').toUpperCase().substring(0, 1) +
                  (s['role']?.toString() ?? 'staff').substring(1),
              isActive: s['is_active'] == true || s['is_active'] == 1,
              isDisabledByPlan: false,
            );
          }).toList();
          setState(() => _staffList = mapped);
        }
      }
    } catch (_) {
      // Fallback
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddUserSheet() {
    final messenger = ScaffoldMessenger.of(context);
    String name = '';
    String phone = '';
    String selectedRole = 'Manager';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            String rolePermissionText = '';
            if (selectedRole == 'Admin') {
              rolePermissionText = 'Full access to bookings, fleet, financial reports, settings & partner payouts.';
            } else if (selectedRole == 'Manager') {
              rolePermissionText = 'Manage bookings, vehicles, customer KYC & create final bills. No financial payout access.';
            } else {
              rolePermissionText = 'Create bookings, perform vehicle pickup/return inspection & view vehicle availability.';
            }

            return AppBottomSheet(
              title: 'Add Staff Account',
              subtitle: 'Create login credentials & assign access role',
              primaryActionText: 'Save & Send Invite',
              onPrimaryAction: () async {
                if (name.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ApiService().createStaffUser(
                    name: name.trim(),
                    phone: phone.trim().isNotEmpty ? phone.trim() : '9800000000',
                    role: selectedRole.toLowerCase(),
                  );
                  _loadStaff();
                } catch (_) {
                  setState(() {
                    _staffList.add(
                      _StaffModel(
                        id: 'USR-0${_staffList.length + 1}',
                        name: name,
                        phone: phone.isEmpty ? '+91 98000 00000' : phone,
                        role: selectedRole,
                        isActive: true,
                        isDisabledByPlan: false,
                      ),
                    );
                  });
                }
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Staff user "$name" created successfully.'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              },
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    label: 'Full Name',
                    hintText: 'e.g. Vikram Sharma',
                    onChanged: (val) => name = val,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Mobile Number',
                    hintText: '10-digit mobile number',
                    keyboardType: TextInputType.phone,
                    onChanged: (val) => phone = val,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Temporary Password',
                    hintText: 'Enter min 6 chars',
                    obscureText: true,
                    onChanged: (val) {},
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Access Role', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Admin', 'Manager', 'Staff'].map((role) {
                      final isSel = selectedRole == role;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setSheetState(() => selectedRole = role);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.primaryCyan.withValues(alpha: 0.15) : AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSel ? AppColors.primaryCyan : AppColors.borderSubtle),
                            ),
                            child: Center(
                              child: Text(
                                role,
                                style: TextStyle(
                                  color: isSel ? AppColors.primaryCyan : AppColors.textSecondary,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.security_rounded, color: AppColors.primaryCyan, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rolePermissionText,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadStaff,
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
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  onPressed: widget.onBack,
                ),
              const SizedBox(width: 4),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Users & Access Roles', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Staff accounts & permissions management', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              CustomButton(
                text: '+ Add Staff',
                width: 105,
                height: 38,
                onPressed: _showAddUserSheet,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Header Counter and Info Note
          Row(
            children: [
              const CounterChip(count: 2, limit: 3, label: 'staff users'),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          const InfoNote(
            text: 'One user can be logged in on one phone at a time.',
            icon: Icons.smartphone_rounded,
            variant: InfoNoteVariant.info,
          ),
          const SizedBox(height: 20),

          // Staff Users List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _staffList.length,
            itemBuilder: (context, i) {
              final user = _staffList[i];
              final isDisabled = user.isDisabledByPlan;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDisabled ? AppColors.surfaceCard.withValues(alpha: 0.5) : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDisabled ? AppColors.borderHairline : AppColors.borderSubtle,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isDisabled ? AppColors.background : AppColors.surfaceHover,
                          child: Icon(
                            Icons.person_rounded,
                            color: isDisabled ? AppColors.textMuted : AppColors.primaryCyan,
                            size: 22,
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
                                    user.name,
                                    style: TextStyle(
                                      color: isDisabled ? AppColors.textSecondary : AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDisabled
                                          ? AppColors.background
                                          : AppColors.primaryCyan.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      user.role.toUpperCase(),
                                      style: TextStyle(
                                        color: isDisabled ? AppColors.textMuted : AppColors.primaryCyan,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.phone,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (isDisabled)
                          StatusChip.disabled()
                        else
                          Switch(
                            value: user.isActive,
                            activeThumbColor: AppColors.primaryCyan,
                            onChanged: (v) {
                              setState(() {
                                user.isActive = v;
                              });
                              ApiService().toggleStaffStatus(user.id, v).catchError((_) => null);
                            },
                          ),
                      ],
                    ),
                    if (isDisabled) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.warningBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.warningBorder),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.lock_rounded, color: AppColors.warningAmber, size: 14),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Plan expired. Renew to reactivate.',
                                style: TextStyle(
                                  color: AppColors.warningAmber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 110),
        ],
      ),
    ),
  );
}
}

class _StaffModel {
  final String id;
  final String name;
  final String phone;
  final String role;
  bool isActive;
  final bool isDisabledByPlan;

  _StaffModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.isActive,
    required this.isDisabledByPlan,
  });
}


