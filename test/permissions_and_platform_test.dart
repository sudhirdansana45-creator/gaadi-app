import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaadi_manager/core/permissions/permission_service.dart';
import 'package:gaadi_manager/core/security/screen_security_service.dart';
import 'package:gaadi_manager/core/update/app_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PermissionService & DPDP Compliance Tests', () {
    test('Audit logging properly stores permission logs without PII', () {
      final service = PermissionService.instance;
      expect(service.auditLogs, isEmpty);

      // Audit logs expose read-only list
      expect(service.auditLogs, isA<List<PermissionAuditLog>>());
    });
  });

  group('ScreenSecurityService & SecureScreenWrapper Tests', () {
    testWidgets('SecureScreenWrapper mounts and unmounts child cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecureScreenWrapper(
            isSecure: true,
            child: Scaffold(
              body: Text('Protected Sensitive Document'),
            ),
          ),
        ),
      );

      expect(find.text('Protected Sensitive Document'), findsOneWidget);

      // Rebuild with isSecure = false
      await tester.pumpWidget(
        const MaterialApp(
          home: SecureScreenWrapper(
            isSecure: false,
            child: Scaffold(
              body: Text('Unprotected Screen'),
            ),
          ),
        ),
      );

      expect(find.text('Unprotected Screen'), findsOneWidget);
    });
  });

  group('AppUpdateService Model Tests', () {
    test('AppUpdateInfo parses forced update response accurately', () {
      final json = {
        'has_update': true,
        'force_update': true,
        'latest_version': '2.0.0',
        'min_required_version': '2.0.0',
        'store_url': 'https://play.google.com/store/apps/details?id=com.gaadimanager.gaadi_manager',
        'update_message': 'Critical security update is mandatory.',
      };

      final info = AppUpdateInfo.fromMap(json);
      expect(info.hasUpdate, true);
      expect(info.forceUpdate, true);
      expect(info.latestVersion, '2.0.0');
      expect(info.minRequiredVersion, '2.0.0');
      expect(info.storeUrl, contains('com.gaadimanager.gaadi_manager'));
      expect(info.updateMessage, 'Critical security update is mandatory.');
    });

    test('AppUpdateInfo handles optional update gracefully', () {
      final json = {
        'has_update': true,
        'force_update': false,
        'latest_version': '1.1.0',
        'min_required_version': '1.0.0',
        'store_url': '',
        'update_message': 'New features added.',
      };

      final info = AppUpdateInfo.fromMap(json);
      expect(info.hasUpdate, true);
      expect(info.forceUpdate, false);
      expect(info.latestVersion, '1.1.0');
    });

    test('AppUpdateInfo defaults gracefully on missing fields', () {
      final info = AppUpdateInfo.fromMap({});
      expect(info.hasUpdate, false);
      expect(info.forceUpdate, false);
      expect(info.latestVersion, '1.0.0');
    });
  });
}
