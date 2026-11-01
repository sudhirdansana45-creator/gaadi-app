import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../utils/external_actions.dart';
import '../utils/platform_util.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final bool forceUpdate;
  final String latestVersion;
  final String minRequiredVersion;
  final String storeUrl;
  final String updateMessage;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.forceUpdate,
    required this.latestVersion,
    required this.minRequiredVersion,
    required this.storeUrl,
    required this.updateMessage,
  });

  factory AppUpdateInfo.fromMap(Map<String, dynamic> map) {
    return AppUpdateInfo(
      hasUpdate: map['has_update'] == true,
      forceUpdate: map['force_update'] == true,
      latestVersion: map['latest_version']?.toString() ?? '1.0.0',
      minRequiredVersion: map['min_required_version']?.toString() ?? '1.0.0',
      storeUrl: map['store_url']?.toString() ?? '',
      updateMessage: map['update_message']?.toString() ??
          'A new version of Gaadi Manager is available with important updates.',
    );
  }
}

class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  /// Checks for available application updates via Laravel API
  Future<AppUpdateInfo?> checkUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final platform = AppPlatform.name;

      final res = await ApiService().checkAppVersion(
        platform: platform,
        currentVersion: packageInfo.version,
      );

      if (res != null && res['success'] == true && res['data'] is Map<String, dynamic>) {
        return AppUpdateInfo.fromMap(res['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Version check failed: $e');
    }
    return null;
  }

  /// Evaluates update status and displays either mandatory or recommended dialog.
  Future<void> evaluateAndPrompt(
    BuildContext context, {
    bool silentIfUpToDate = true,
  }) async {
    final updateInfo = await checkUpdate();
    if (updateInfo == null) return;

    if (!context.mounted) return;

    if (updateInfo.forceUpdate) {
      // Mandatory Update - Blocking dialog
      await _showForceUpdateDialog(context, updateInfo);
    } else if (updateInfo.hasUpdate) {
      // Optional Update - Friendly recommendation
      await _showOptionalUpdateDialog(context, updateInfo);
    } else if (!silentIfUpToDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gaadi Manager is up to date!'),
          backgroundColor: AppColors.surfaceCard,
        ),
      );
    }
  }

  Future<void> _showForceUpdateDialog(BuildContext context, AppUpdateInfo info) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF161B26) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.criticalRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.system_security_update_rounded, color: AppColors.criticalRed, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Update Required',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.updateMessage,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Latest Version: ${info.latestVersion}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryCyan,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCyan,
                  foregroundColor: const Color(0xFF0F131D),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  ExternalActions.openAppStore();
                },
                child: const Text('Update Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOptionalUpdateDialog(BuildContext context, AppUpdateInfo info) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161B26) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.new_releases_rounded, color: AppColors.primaryCyan, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Update Available',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info.updateMessage,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Version ${info.latestVersion} is now available.',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryCyan,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              foregroundColor: const Color(0xFF0F131D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ExternalActions.openAppStore();
            },
            child: const Text('Update Now', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
