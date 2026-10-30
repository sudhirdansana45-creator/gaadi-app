import '../services/api_client.dart';

class PlanGuard {
  static Map<String, dynamic>? get _user => ApiClient().currentUser;
  static Map<String, dynamic>? get _plan =>
      _user?['plan'] is Map ? _user!['plan'] : (_user?['subscription']?['plan'] is Map ? _user!['subscription']['plan'] : null);
  static String get _planSlug => _plan?['slug']?.toString() ?? 'free';
  static bool get isFreePlan => _planSlug == 'free';

  static bool canAddVehicle() {
    return true;
  }

  static bool canAddPartner() {
    return true;
  }

  static bool canCreateBill() {
    return true;
  }

  static bool canUseUsers() {
    return !isFreePlan;
  }

  static bool canUseWhatsApp() {
    return !isFreePlan;
  }

  static bool isReportLocked(String reportId) {
    if (isFreePlan) {
      return reportId != 'daily-monthly' && reportId != 'daily_monthly';
    }
    return false;
  }
}
