import '../data/dummy_plan_data.dart';

class PlanGuard {
  static bool canAddVehicle() {
    final data = DummyPlanData();
    if (data.activeState == PlanState.expired) return false;
    return !data.isVehicleLimitReached;
  }

  static bool canAddPartner() {
    final data = DummyPlanData();
    if (data.activeState == PlanState.expired) return false;
    return !data.isPartnerLimitReached;
  }

  static bool canCreateBill() {
    final data = DummyPlanData();
    if (data.activeState == PlanState.expired) return false;
    return !data.isDailyBillLimitReached;
  }

  static bool canUseUsers() {
    final data = DummyPlanData();
    return data.activeState != PlanState.free && data.activeState != PlanState.expired;
  }

  static bool canUseWhatsApp() {
    final data = DummyPlanData();
    return data.activeState != PlanState.free && data.activeState != PlanState.expired;
  }

  static bool isReportLocked(String reportId) {
    final data = DummyPlanData();
    if (data.activeState == PlanState.free) {
      return reportId != 'daily-monthly' && reportId != 'daily_monthly';
    }
    return false;
  }
}
