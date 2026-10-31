import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_colors.dart';

/// Event log entry for DPDP / compliance tracking (No PII stored)
class PermissionAuditLog {
  final DateTime timestamp;
  final String permissionName;
  final String status;
  final String source;

  const PermissionAuditLog({
    required this.timestamp,
    required this.permissionName,
    required this.status,
    required this.source,
  });

  Map<String, dynamic> toMap() => {
    'timestamp': timestamp.toIso8601String(),
    'permission': permissionName,
    'status': status,
    'source': source,
  };
}

class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  final List<PermissionAuditLog> _auditLogs = [];
  List<PermissionAuditLog> get auditLogs => List.unmodifiable(_auditLogs);

  void _log(String permissionName, String status, String source) {
    final entry = PermissionAuditLog(
      timestamp: DateTime.now().toUtc(),
      permissionName: permissionName,
      status: status,
      source: source,
    );
    _auditLogs.add(entry);
    debugPrint('[PermissionService DPDP Audit] ${entry.permissionName} -> ${entry.status} ($source)');
  }

  /// Checks the current status of a permission.
  Future<PermissionStatus> checkStatus(Permission permission) async {
    return await permission.status;
  }

  /// Opens the OS Application Settings screen.
  Future<bool> openSettings() async {
    _log('settings', 'opened', 'user_action');
    return await openAppSettings();
  }

  /// Camera permission request with just-in-time rationale.
  Future<bool> requestCamera({
    required BuildContext context,
    String? title,
    String? message,
  }) async {
    const perm = Permission.camera;
    final current = await perm.status;

    if (current.isGranted) {
      _log('camera', 'already_granted', 'direct_check');
      return true;
    }

    if (current.isPermanentlyDenied) {
      _log('camera', 'permanently_denied', 'prompt_settings');
      if (context.mounted) {
        await _showSettingsDialog(
          context: context,
          title: 'Camera Permission Needed',
          message:
              'Camera permission was previously disabled. Please allow camera access in App Settings to take driving licence and vehicle photos.',
          permissionName: 'Camera',
        );
      }
      return false;
    }

    // Show friendly in-app rationale before invoking system dialog
    if (context.mounted) {
      final proceed = await showRationaleSheet(
        context: context,
        icon: Icons.camera_alt_rounded,
        title: title ?? 'Camera Access Required',
        description: message ??
            'Gaadi Manager uses your camera to capture customer Driving Licences, ID proofs, and vehicle handover inspection photos.',
        dpdpNotice:
            'Images captured are strictly stored in your secure business account for rental compliance and vehicle safety.',
        confirmLabel: 'Continue to Allow',
        permissionName: 'Camera',
      );

      if (!proceed) {
        _log('camera', 'rationale_dismissed', 'in_app_pre_prompt');
        return false;
      }
    }

    final result = await perm.request();
    _log('camera', result.toString(), 'system_prompt');

    if (result.isPermanentlyDenied && context.mounted) {
      await _showSettingsDialog(
        context: context,
        title: 'Camera Access Disabled',
        message:
            'Camera access is required for scanning customer driving licences. You can enable it anytime in App Settings.',
        permissionName: 'Camera',
      );
    }

    return result.isGranted;
  }

  /// Photos / Storage permission request (Limited / Partial access handled gracefully).
  Future<bool> requestPhotos({
    required BuildContext context,
    String? title,
    String? message,
  }) async {
    // Android 13+ (API 33+) uses photos permission; iOS uses photos.
    final Permission perm = Platform.isIOS ? Permission.photos : Permission.photos;
    final current = await perm.status;

    // Support iOS 14+ limited access and Android 14 partial access
    if (current.isGranted || current.isLimited) {
      _log('photos', current.isLimited ? 'limited' : 'granted', 'direct_check');
      return true;
    }

    if (current.isPermanentlyDenied) {
      _log('photos', 'permanently_denied', 'prompt_settings');
      if (context.mounted) {
        await _showSettingsDialog(
          context: context,
          title: 'Photo Library Permission Needed',
          message:
              'Photo access is currently disabled. Please enable photo access in App Settings to attach document or vehicle images.',
          permissionName: 'Photos',
        );
      }
      return false;
    }

    if (context.mounted) {
      final proceed = await showRationaleSheet(
        context: context,
        icon: Icons.photo_library_rounded,
        title: title ?? 'Photo Library Access',
        description: message ??
            'Gaadi Manager needs access to your photos so you can select customer ID proofs, vehicle photos, and partner documents.',
        dpdpNotice:
            'Only the specific photos you select will be uploaded and linked to your rental records.',
        confirmLabel: 'Select Photos',
        permissionName: 'Photos',
      );

      if (!proceed) {
        _log('photos', 'rationale_dismissed', 'in_app_pre_prompt');
        return false;
      }
    }

    final result = await perm.request();
    _log('photos', result.toString(), 'system_prompt');

    // Limited access on iOS/Android 14 is considered valid for picking
    return result.isGranted || result.isLimited;
  }

  /// Notification permission request (Post-login friendly pre-prompt).
  Future<bool> requestNotifications({
    required BuildContext context,
    bool isPrePrompt = false,
  }) async {
    const perm = Permission.notification;
    final current = await perm.status;

    if (current.isGranted) {
      _log('notification', 'already_granted', 'direct_check');
      return true;
    }

    if (current.isPermanentlyDenied) {
      _log('notification', 'permanently_denied', 'silent_skip');
      if (!isPrePrompt && context.mounted) {
        await _showSettingsDialog(
          context: context,
          title: 'Notifications Disabled',
          message:
              'Push notifications are turned off in Settings. Enable notifications to receive timely vehicle return alerts and plan expiry reminders.',
          permissionName: 'Notifications',
        );
      }
      return false;
    }

    if (context.mounted) {
      final proceed = await showRationaleSheet(
        context: context,
        icon: Icons.notifications_active_rounded,
        title: 'Stay Notified on Rentals & Plans',
        description:
            'Get instant alerts for upcoming vehicle returns, pending customer payments, and renewal reminders before plan expiry.',
        dpdpNotice:
            'You will only receive operational rental and billing alerts. Promotional spam is never sent.',
        confirmLabel: 'Turn On Alerts',
        permissionName: 'Notifications',
      );

      if (!proceed) {
        _log('notification', 'rationale_dismissed', 'pre_prompt');
        return false;
      }
    }

    final result = await perm.request();
    _log('notification', result.toString(), 'system_prompt');
    return result.isGranted;
  }

  /// Beautiful bottom sheet explaining rationale before system dialog.
  Future<bool> showRationaleSheet({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required String dpdpNotice,
    required String confirmLabel,
    required String permissionName,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final isDark = Theme.of(sheetCtx).brightness == Brightness.dark;
        final cardBg = isDark ? const Color(0xFF161B26) : Colors.white;
        final primaryColor = AppColors.primaryCyan;
        final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
        final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final borderCol = isDark ? const Color(0xFF232B3E) : const Color(0xFFE2E8F0);

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderCol),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: primaryColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Gaadi Manager Permission Request',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                // DPDP Indian Digital Personal Data Protection compliance notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F131D) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderCol.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.successGreen, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dpdpNotice,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: borderCol),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(sheetCtx, false),
                        child: Text(
                          'Not Now',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: const Color(0xFF0F131D),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(sheetCtx, true),
                        child: Text(
                          confirmLabel,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  /// Dialog when permission is permanently denied with direct action to Open Settings.
  Future<void> _showSettingsDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String permissionName,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161B26) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.settings_suggest_rounded, color: AppColors.warningAmber, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              foregroundColor: const Color(0xFF0F131D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(dlgCtx);
              openSettings();
            },
            child: const Text('Open Settings', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
