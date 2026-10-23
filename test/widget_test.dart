import 'package:flutter_test/flutter_test.dart';
import 'package:gaadi_manager/main.dart';
import 'package:gaadi_manager/core/api_config.dart';
import 'package:gaadi_manager/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App loads cleanly test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await ApiClient().init();
    await tester.pumpWidget(const GaadiManagerApp());
    expect(find.byType(GaadiManagerApp), findsOneWidget);
  });

  test('ApiConfig verifies domain and endpoints structure', () {
    expect(ApiConfig.baseDomain, 'gaadi.ersudhir.cloud');
    expect(ApiConfig.baseUrl, 'https://gaadi.ersudhir.cloud/api/v1');
    expect(ApiConfig.login, '/auth/login');
    expect(ApiConfig.dashboardStats, '/dashboard/stats');
    expect(ApiConfig.vehicles, '/vehicles');
    expect(ApiConfig.bookings, '/bookings');
    expect(ApiConfig.customers, '/customers');
    expect(ApiConfig.plans, '/plans');

    final headers = ApiConfig.headers(token: 'test_token');
    expect(headers['Authorization'], 'Bearer test_token');
    expect(headers['Accept'], 'application/json');
  });

  test('ApiClient manages bearer token state correctly', () async {
    SharedPreferences.setMockInitialValues({});
    final client = ApiClient();
    await client.init();
    expect(client.isAuthenticated, false);

    await client.setToken('sample_token_123');
    expect(client.isAuthenticated, true);
    expect(client.token, 'sample_token_123');

    await client.clearSession();
    expect(client.isAuthenticated, false);
    expect(client.token, isNull);
  });
}
