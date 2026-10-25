import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/lock_badge.dart';
import '../../data/dummy_plan_data.dart';
import '../../services/api_service.dart';
import '../modals/locked_feature_sheet.dart';

class SettingsScreen extends StatefulWidget {
  final Function(String route, {dynamic args}) onNavigate;
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _selectedTheme;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _selectedTheme = ThemeController.modeString;
  }

  void _showLockedSheet(String featureName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LockedFeatureSheet(
        onClose: () => Navigator.pop(ctx),
        onUpgrade: () {
          Navigator.pop(ctx);
          widget.onNavigate('plans_and_usage');
        },
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.borderSubtle),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.criticalRed, size: 24),
            SizedBox(width: 10),
            Text(
              'Delete Account',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete your operator account? All fleet data, customer records, and active bookings will be permanently erased. This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Cancel',
                  variant: ButtonVariant.ghost,
                  height: 42,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomButton(
                  text: 'Delete Account',
                  variant: ButtonVariant.destructive,
                  height: 42,
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account deletion request submitted.'),
                        backgroundColor: AppColors.criticalRed,
                      ),
                    );
                    widget.onLogout();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFreePlan = DummyPlanData().activeState == PlanState.free;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings & Configuration', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Manage business profile, GST rates, T&C & security', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 20),

          // Business Profile Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(Icons.business_rounded, color: AppColors.textDark, size: 28),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rajesh Fleet Mobility', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17)),
                      Text('GSTIN: 07AAAAA0000A1Z5 • Delhi NCR', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                CustomButton(
                  text: 'Edit Profile',
                  variant: ButtonVariant.secondary,
                  width: 90,
                  height: 36,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _sectionTitle('Platform & Subscription Tools'),
          _tile(
            Icons.workspace_premium_rounded,
            'Plans & Usage Quota',
            isFreePlan ? 'Active: Starter Free Plan (5 Cars max)' : 'Active: Growth Plan (18/25 Cars)',
            () => widget.onNavigate('plans_and_usage'),
          ),
          _tile(
            Icons.mark_chat_read_rounded,
            'WhatsApp Templates & Wallet',
            '1,420 automated credits left',
            isFreePlan ? () => _showLockedSheet('WhatsApp Templates & Wallet') : () => widget.onNavigate('whatsapp_wallet'),
            isLocked: isFreePlan,
          ),
          _tile(
            Icons.badge_rounded,
            'Users and Roles',
            '3 active manager accounts',
            isFreePlan ? () => _showLockedSheet('Users and Roles') : () => widget.onNavigate('users_and_roles'),
            isLocked: isFreePlan,
          ),

          const SizedBox(height: 16),
          _sectionTitle('Preferences'),
          _buildThemeSelector(),
          _buildLanguagePicker(),

          const SizedBox(height: 16),
          _sectionTitle('Account & Session'),
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.criticalRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.criticalRed.withValues(alpha: 0.3)),
            ),
            child: ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: AppColors.criticalRed, size: 22),
              title: const Text(
                'Delete Account',
                style: TextStyle(color: AppColors.criticalRed, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: const Text(
                'Permanently delete your account & fleet data',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.criticalRed, size: 20),
              onTap: _showDeleteAccountDialog,
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Logout from Operator Desk',
            variant: ButtonVariant.destructive,
            icon: Icons.power_settings_new_rounded,
            onPressed: () async {
              try {
                await ApiService().logout();
              } catch (_) {}
              widget.onLogout();
            },
          ),
          const SizedBox(height: 110),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Text(title, style: const TextStyle(color: AppColors.primaryCyan, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _tile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isLocked = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isLocked ? AppColors.surfaceCard.withValues(alpha: 0.7) : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isLocked ? AppColors.borderHairline : AppColors.borderSubtle),
      ),
      child: ListTile(
        leading: Icon(icon, color: isLocked ? AppColors.textMuted : AppColors.primaryCyan, size: 22),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isLocked ? AppColors.textSecondary : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            if (isLocked) ...[
              const SizedBox(width: 6),
              const LockBadge(planPrice: '₹99'),
            ],
          ],
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
        onTap: onTap,
      ),
    );
  }

  Widget _buildThemeSelector() {
    final options = [
      {'label': 'Dark', 'icon': Icons.dark_mode_rounded},
      {'label': 'Light', 'icon': Icons.light_mode_rounded},
      {'label': 'System', 'icon': Icons.settings_brightness_rounded},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Theme Mode',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose your preferred visual theme mode',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: options.map((opt) {
              final isSelected = _selectedTheme == opt['label'];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTheme = opt['label'] as String;
                      ThemeController.setThemeModeFromString(_selectedTheme);
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryCyan.withValues(alpha: 0.15) : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryCyan : AppColors.borderSubtle,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          opt['icon'] as IconData,
                          color: isSelected ? AppColors.primaryCyan : AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          opt['label'] as String,
                          style: TextStyle(
                            color: isSelected ? AppColors.primaryCyan : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagePicker() {
    final languages = [
      {'label': 'English', 'sub': 'EN'},
      {'label': 'Hindi', 'sub': 'हिंदी'},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'App Language / भाषा',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select your preferred interface language',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: languages.map((lang) {
              final isSelected = _selectedLanguage == lang['label'];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedLanguage = lang['label'] as String;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryCyan.withValues(alpha: 0.15) : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryCyan : AppColors.borderSubtle,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: isSelected ? AppColors.primaryCyan : AppColors.textMuted,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${lang['label']} (${lang['sub']})',
                          style: TextStyle(
                            color: isSelected ? AppColors.primaryCyan : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

