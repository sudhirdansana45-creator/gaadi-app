/// Central API Configuration for Gaadi Manager Flutter Application.
/// All endpoint URLs, domain constants, and header helpers are centralized here.
class ApiConfig {
  /// Base domain specified by user for backend deployment.
  static const String baseDomain = 'gaadi.ersudhir.cloud';

  /// Root API V1 endpoint URL.
  static const String baseUrl = 'https://$baseDomain/api/v1';

  // --- Auth & Session Endpoints ---
  static const String login = '/auth/login';
  static const String verifyOtp = '/auth/verify-otp';
  static const String register = '/auth/register';
  static const String forgotPin = '/auth/forgot-pin';
  static const String resetPin = '/auth/reset-pin';
  static const String profile = '/auth/profile';
  static const String logout = '/auth/logout';
  static const String deviceToken = '/auth/device-token';

  // --- App Diagnostics & Version Check ---
  static const String versionCheck = '/app/version-check';
  static const String appConfig = '/app/config';

  // --- Dashboard ---
  static const String dashboardStats = '/dashboard/stats';

  // --- Vehicles ---
  static const String vehicles = '/vehicles';
  static String vehicleDetail(String id) => '/vehicles/$id';
  static String vehicleStatus(String id) => '/vehicles/$id/status';

  // --- Customers & KYC ---
  static const String customers = '/customers';
  static String customerDetail(String id) => '/customers/$id';
  static String customerBlacklist(String id) => '/customers/$id/blacklist';

  // --- Bookings Flow ---
  static const String bookings = '/bookings';
  static String bookingDetail(String id) => '/bookings/$id';
  static String bookingPickup(String id) => '/bookings/$id/pickup';
  static String bookingExtend(String id) => '/bookings/$id/extend';
  static String bookingReturn(String id) => '/bookings/$id/return';
  static String bookingPayment(String id) => '/bookings/$id/payment';
  static String bookingCancel(String id) => '/bookings/$id/cancel';

  // --- Partners & Investor Fleet ---
  static const String partners = '/partners';
  static String partnerDetail(String id) => '/partners/$id';
  static String partnerLedger(String id) => '/partners/$id/ledger';
  static String partnerPayout(String id) => '/partners/$id/payout';

  // --- Store & Accessories ---
  static const String storeProducts = '/store/products';
  static String storeProductDetail(String id) => '/store/products/$id';
  static const String storeOrders = '/store/orders';

  // --- Reports & Business Metrics ---
  static const String reportsSummary = '/reports/summary';
  static const String reportsVehicleWise = '/reports/vehicle-wise';

  // --- Subscriptions & Quota ---
  static const String plans = '/plans';
  static const String mySubscription = '/subscription/my-plan';
  static const String upgradeRequest = '/subscription/upgrade-request';

  // --- Staff & Sub-Accounts ---
  static const String staff = '/staff';
  static String staffToggle(String id) => '/staff/$id/toggle-status';

  // --- Settings & WhatsApp ---
  static const String whatsappSettings = '/settings/whatsapp';
  static const String businessProfile = '/settings/business';

  /// Standard Headers for API requests
  static Map<String, String> headers({String? token}) {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}
