import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/counter_chip.dart';
import '../../widgets/info_note.dart';
import '../../services/api_service.dart';
import '../../services/api_client.dart';
import '../../core/utils/external_actions.dart';

class StaffPermissionDef {
  final String key;
  final String label;
  final String description;
  final IconData icon;
  final bool isDefault;

  const StaffPermissionDef({
    required this.key,
    required this.label,
    required this.description,
    required this.icon,
    this.isDefault = false,
  });
}

const List<StaffPermissionDef> kAvailablePermissions = [
  StaffPermissionDef(
    key: 'bookings_create',
    label: 'Create New Booking',
    description: 'Create rentals, customer bills & check-outs',
    icon: Icons.add_circle_outline_rounded,
    isDefault: true,
  ),
  StaffPermissionDef(
    key: 'bookings_manage',
    label: 'Manage & Return Bookings',
    description: 'Inspect returns, calculate late fees & close trips',
    icon: Icons.checklist_rtl_rounded,
  ),
  StaffPermissionDef(
    key: 'vehicles_create',
    label: 'Add & Create Vehicles',
    description: 'Register new cars & bikes with document photos',
    icon: Icons.directions_car_filled_rounded,
  ),
  StaffPermissionDef(
    key: 'vehicles_manage',
    label: 'Edit & Update Fleet',
    description: 'Modify daily pricing, maintenance flags & specs',
    icon: Icons.build_circle_outlined,
  ),
  StaffPermissionDef(
    key: 'payments_collect',
    label: 'Collect & Settle Payments',
    description: 'Record cash, UPI, & partial advance receipts',
    icon: Icons.payments_outlined,
  ),
  StaffPermissionDef(
    key: 'customers_manage',
    label: 'Customer KYC & Directory',
    description: 'Scan DL, verify Aadhaar & customer profiles',
    icon: Icons.badge_outlined,
  ),
  StaffPermissionDef(
    key: 'partners_manage',
    label: 'Partners & Investor Ledger',
    description: 'View investor partners & calculate revenue shares',
    icon: Icons.handshake_outlined,
  ),
  StaffPermissionDef(
    key: 'reports_view',
    label: 'Financial Reports & P&L',
    description: 'View daily collections, revenue & fleet analytics',
    icon: Icons.bar_chart_rounded,
  ),
  StaffPermissionDef(
    key: 'settings_access',
    label: 'Settings & Configurations',
    description: 'Manage store templates & system settings',
    icon: Icons.settings_suggest_rounded,
  ),
];

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
  late List<_StaffModel> _staffList;
  bool _isLoading = false;
  int _staffLimit = 5;

  @override
  void initState() {
    super.initState();
    final user = ApiClient().currentUser;
    final String currentName = user?['name']?.toString().trim() ?? 'Fleet Admin';
    final String currentPhone = user?['mobile'] != null ? '+91 ${user!['mobile']}' : 'Primary Admin';

    _staffList = [
      _StaffModel(
        id: 'ADMIN',
        name: currentName,
        phone: currentPhone,
        role: 'Admin (Owner)',
        permissions: const ['*'],
        isActive: true,
        isDisabledByPlan: false,
        hasPassword: true,
      ),
    ];
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    final user = ApiClient().currentUser;
    final String currentName = user?['name']?.toString().trim() ?? 'Fleet Admin';
    final String currentPhone = user?['mobile'] != null ? '+91 ${user!['mobile']}' : 'Primary Admin';

    try {
      final sub = await ApiService().getMySubscription();
      if (sub != null && sub['data']?['quota'] is Map && mounted) {
        final q = sub['data']['quota'];
        setState(() {
          _staffLimit = (q['max_staff'] as num?)?.toInt() ?? 5;
        });
      }

      final res = await ApiService().getStaffUsers();
      if (res != null && res['data'] is List && mounted) {
        final List list = res['data'];
        final mapped = list.map((s) {
          final roleStr = s['role']?.toString() ?? 'Staff';
          final capitalizedRole = roleStr.isNotEmpty
              ? roleStr.substring(0, 1).toUpperCase() + roleStr.substring(1).toLowerCase()
              : 'Staff';
          final List<String> perms = (s['permissions'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              ['bookings_create'];

          return _StaffModel(
            id: s['id']?.toString() ?? '',
            name: s['name']?.toString() ?? '',
            phone: s['mobile']?.toString() ?? s['phone']?.toString() ?? '',
            email: s['email']?.toString(),
            role: capitalizedRole,
            permissions: perms,
            isActive: s['is_active'] == true || s['is_active'] == 1,
            isDisabledByPlan: false,
            hasPassword: s['has_password'] == true,
          );
        }).toList();

        setState(() {
          _staffList = [
            _StaffModel(
              id: 'ADMIN',
              name: currentName,
              phone: currentPhone,
              role: 'Admin (Owner)',
              permissions: const ['*'],
              isActive: true,
              isDisabledByPlan: false,
              hasPassword: true,
            ),
            ...mapped,
          ];
        });
      }
    } catch (_) {
      // Fallback
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showStaffModal({_StaffModel? staff}) {
    final isEditing = staff != null;
    final nameController = TextEditingController(text: isEditing ? staff.name : '');
    final phoneController = TextEditingController(text: isEditing ? staff.phone.replaceAll('+91', '').trim() : '');
    final emailController = TextEditingController(text: isEditing ? (staff.email ?? '') : '');
    final pinController = TextEditingController();
    String selectedRole = isEditing ? staff.role : 'Staff';

    // Permissions: default only vehicle new booking ('bookings_create') unless edited
    final Set<String> selectedPermissions = isEditing
        ? Set<String>.from(staff.permissions)
        : {'bookings_create'};

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131722),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.90,
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Staff & Permissions' : 'Add Staff Member',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Assign user-wise permissions and login PIN',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white60),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF2A3854), height: 24),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextField(
                            label: 'Full Name *',
                            hintText: 'e.g. Rahul Sharma',
                            controller: nameController,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: 'Mobile Number *',
                            hintText: '10-digit mobile number for login',
                            keyboardType: TextInputType.phone,
                            controller: phoneController,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: 'Email (Optional)',
                            hintText: 'e.g. staff@example.com',
                            keyboardType: TextInputType.emailAddress,
                            controller: emailController,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: isEditing ? 'Change Login PIN / Password' : 'Login PIN / Password *',
                            hintText: isEditing ? 'Leave blank to keep current PIN' : 'Enter 4+ digit security PIN',
                            obscureText: true,
                            keyboardType: TextInputType.visiblePassword,
                            controller: pinController,
                          ),
                          const SizedBox(height: 16),

                          // Role Selector
                          const Text(
                            'Staff Role / Designation',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: ['Staff', 'Driver', 'Supervisor', 'Manager'].map((role) {
                              final isSel = selectedRole.toLowerCase() == role.toLowerCase();
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setSheetState(() => selectedRole = role),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? AppColors.primaryCyan.withValues(alpha: 0.15)
                                          : const Color(0xFF1B1F2B),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSel ? AppColors.primaryCyan : const Color(0xFF2A3854),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        role,
                                        style: TextStyle(
                                          color: isSel ? AppColors.primaryCyan : AppColors.textSecondary,
                                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Granular Permissions Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Assigned Permissions (User-Wise)',
                                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Default: Vehicle New Booking only',
                                    style: TextStyle(color: Color(0xFF4EDEAE), fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setSheetState(() {
                                        selectedPermissions.clear();
                                        selectedPermissions.addAll(kAvailablePermissions.map((p) => p.key));
                                      });
                                    },
                                    child: const Text('Select All', style: TextStyle(color: AppColors.primaryCyan, fontSize: 11)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setSheetState(() {
                                        selectedPermissions.clear();
                                        selectedPermissions.add('bookings_create');
                                      });
                                    },
                                    child: const Text('Reset', style: TextStyle(color: Colors.white60, fontSize: 11)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Permission Checklist Items
                          ...kAvailablePermissions.map((perm) {
                            final isChecked = selectedPermissions.contains(perm.key);
                            final isBookingDefault = perm.key == 'bookings_create';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? const Color(0xFF1B2332)
                                    : const Color(0xFF161A24),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isChecked
                                      ? AppColors.primaryCyan.withValues(alpha: 0.5)
                                      : const Color(0xFF242A38),
                                ),
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                leading: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isChecked
                                        ? AppColors.primaryCyan.withValues(alpha: 0.15)
                                        : Colors.white10,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    perm.icon,
                                    color: isChecked ? AppColors.primaryCyan : Colors.white60,
                                    size: 18,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      perm.label,
                                      style: TextStyle(
                                        color: isChecked ? Colors.white : Colors.white70,
                                        fontWeight: isChecked ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (isBookingDefault) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4EDEAE).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'DEFAULT',
                                          style: TextStyle(
                                            color: Color(0xFF4EDEAE),
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  perm.description,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                                trailing: Checkbox(
                                  value: isChecked,
                                  activeColor: AppColors.primaryCyan,
                                  checkColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (val) {
                                    setSheetState(() {
                                      if (val == true) {
                                        selectedPermissions.add(perm.key);
                                      } else {
                                        selectedPermissions.remove(perm.key);
                                      }
                                    });
                                  },
                                ),
                                onTap: () {
                                  setSheetState(() {
                                    if (isChecked) {
                                      selectedPermissions.remove(perm.key);
                                    } else {
                                      selectedPermissions.add(perm.key);
                                    }
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  CustomButton(
                    text: isSaving
                        ? 'Saving...'
                        : (isEditing ? 'Save Staff & Permissions' : 'Create Staff Member'),
                    icon: isSaving ? null : Icons.save_rounded,
                    isLoading: isSaving,
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            final phone = phoneController.text.trim();
                            final email = emailController.text.trim();
                            final pin = pinController.text.trim();

                            if (name.isEmpty || phone.length < 10) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter staff name and valid 10-digit mobile number.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }

                            setSheetState(() => isSaving = true);
                            try {
                              if (isEditing) {
                                await ApiService().updateStaffUser(
                                  staff.id,
                                  name: name,
                                  phone: phone,
                                  email: email.isNotEmpty ? email : null,
                                  role: selectedRole.toLowerCase(),
                                  permissions: selectedPermissions.toList(),
                                  password: pin.isNotEmpty ? pin : null,
                                );
                              } else {
                                await ApiService().createStaffUser(
                                  name: name,
                                  phone: phone,
                                  email: email.isNotEmpty ? email : null,
                                  role: selectedRole.toLowerCase(),
                                  permissions: selectedPermissions.toList(),
                                  password: pin.isNotEmpty ? pin : null,
                                );
                              }

                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Staff member "$name" saved with custom permissions!'),
                                    backgroundColor: const Color(0xFF00C853),
                                  ),
                                );
                                _loadStaff();
                              }
                            } catch (e) {
                              setSheetState(() => isSaving = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error saving staff: $e'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteStaff(_StaffModel staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Staff Member?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to remove "${staff.name}"? They will no longer be able to log in or access your fleet data.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService().deleteStaffUser(staff.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Staff member "${staff.name}" removed.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  _loadStaff();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete staff: $e')),
                  );
                }
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F131D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'Staff & Role Permissions',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Color(0xFF4EDEAE)),
            tooltip: 'Share APK',
            onPressed: () => ExternalActions.shareApk(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Refresh',
            onPressed: _loadStaff,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
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

                // Top Header with Share APK Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161F2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A3854)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4EDEAE).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.android_rounded, color: Color(0xFF4EDEAE), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Share Gaadi Manager APK',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Directly share app APK with your fleet staff so they can install & log in.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4EDEAE),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.share_rounded, size: 14),
                        label: const Text('Share APK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () => ExternalActions.shareApk(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quota & Team Count
                Row(
                  children: [
                    CounterChip(count: _staffList.length, limit: _staffLimit, label: 'team users'),
                    const Spacer(),
                    CustomButton(
                      text: '+ Add Staff',
                      width: 110,
                      height: 36,
                      onPressed: () => _showStaffModal(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                const InfoNote(
                  text: 'Staff members log in on their phones with their mobile number and assigned PIN to perform operations.',
                  icon: Icons.security_rounded,
                  variant: InfoNoteVariant.info,
                ),
                const SizedBox(height: 18),

                // Staff Users List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _staffList.length,
                  itemBuilder: (context, i) {
                    final staff = _staffList[i];
                    final isOwner = staff.id == 'ADMIN';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B26),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isOwner
                              ? const Color(0xFFFBBF24).withValues(alpha: 0.4)
                              : const Color(0xFF242A38),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: isOwner
                                    ? const Color(0xFFFBBF24).withValues(alpha: 0.15)
                                    : const Color(0xFF1B2332),
                                child: Icon(
                                  isOwner ? Icons.shield_rounded : Icons.person_rounded,
                                  color: isOwner ? const Color(0xFFFBBF24) : AppColors.primaryCyan,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          staff.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isOwner
                                                ? const Color(0xFFFBBF24).withValues(alpha: 0.15)
                                                : AppColors.primaryCyan.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            staff.role.toUpperCase(),
                                            style: TextStyle(
                                              color: isOwner ? const Color(0xFFFBBF24) : AppColors.primaryCyan,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      staff.phone,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              if (isOwner)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'OWNER',
                                    style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                )
                              else
                                Switch(
                                  value: staff.isActive,
                                  activeThumbColor: AppColors.primaryCyan,
                                  onChanged: (v) {
                                    setState(() => staff.isActive = v);
                                    ApiService().toggleStaffStatus(staff.id, v).catchError((_) => null);
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Color(0xFF242A38), height: 1),
                          const SizedBox(height: 10),

                          // Permissions Chips
                          const Text(
                            'Assigned Permissions:',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: isOwner
                                ? [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('All Access (Admin Full Control)',
                                          style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w600)),
                                    )
                                  ]
                                : staff.permissions.map((pk) {
                                    final def = kAvailablePermissions.firstWhere(
                                      (p) => p.key == pk,
                                      orElse: () => StaffPermissionDef(
                                        key: pk,
                                        label: pk.replaceAll('_', ' ').toUpperCase(),
                                        description: '',
                                        icon: Icons.check_circle_outline_rounded,
                                      ),
                                    );
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: pk == 'bookings_create'
                                            ? const Color(0xFF4EDEAE).withValues(alpha: 0.12)
                                            : const Color(0xFF2A3854).withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(def.icon, size: 12, color: pk == 'bookings_create' ? const Color(0xFF4EDEAE) : Colors.white70),
                                          const SizedBox(width: 4),
                                          Text(
                                            def.label,
                                            style: TextStyle(
                                              color: pk == 'bookings_create' ? const Color(0xFF4EDEAE) : Colors.white70,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                          ),

                          if (!isOwner) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF25D366),
                                    side: const BorderSide(color: Color(0xFF25D366), width: 0.8),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.send_rounded, size: 12),
                                  label: const Text('WhatsApp APK', style: TextStyle(fontSize: 11)),
                                  onPressed: () {
                                    ExternalActions.openWhatsApp(
                                      phone: staff.phone,
                                      message: 'Hello ${staff.name}, please install Gaadi Manager APK to access your fleet staff account:\nhttps://gaadi.ersudhir.cloud/download/gaadi-manager.apk\n\nLogin Mobile: ${staff.phone}',
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryCyan,
                                    side: const BorderSide(color: AppColors.primaryCyan, width: 0.8),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.edit_rounded, size: 12),
                                  label: const Text('Edit Permissions', style: TextStyle(fontSize: 11)),
                                  onPressed: () => _showStaffModal(staff: staff),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Delete Staff',
                                  onPressed: () => _confirmDeleteStaff(staff),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StaffModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String role;
  final List<String> permissions;
  bool isActive;
  final bool isDisabledByPlan;
  final bool hasPassword;

  _StaffModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    required this.permissions,
    required this.isActive,
    required this.isDisabledByPlan,
    this.hasPassword = false,
  });
}
