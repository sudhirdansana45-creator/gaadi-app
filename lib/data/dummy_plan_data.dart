import 'package:flutter/foundation.dart';

enum PlanState { free, expiringSoon, grace, expired }
enum UserRole { admin, manager, staff }

class PlanModel {
  final String id;
  final String name;
  final double pricePerMonth;
  final int vehicleLimit; // -1 for unlimited
  final int partnerLimit;
  final int dailyBillLimit;
  final int staffUserLimit;
  final bool isCurrent;
  final List<String> features;

  const PlanModel({
    required this.id,
    required this.name,
    required this.pricePerMonth,
    required this.vehicleLimit,
    required this.partnerLimit,
    required this.dailyBillLimit,
    required this.staffUserLimit,
    this.isCurrent = false,
    required this.features,
  });
}

class PlanUsageData {
  final int vehiclesUsed;
  final int vehicleLimit;
  final int partnersUsed;
  final int partnerLimit;
  final int billsUsedToday;
  final int dailyBillLimit;
  final int staffUsersUsed;
  final int staffUserLimit;
  final bool isStaffLocked;

  const PlanUsageData({
    required this.vehiclesUsed,
    required this.vehicleLimit,
    required this.partnersUsed,
    required this.partnerLimit,
    required this.billsUsedToday,
    required this.dailyBillLimit,
    required this.staffUsersUsed,
    required this.staffUserLimit,
    required this.isStaffLocked,
  });

  bool get isVehicleLimitReached => vehicleLimit != -1 && vehiclesUsed >= vehicleLimit;
  bool get isPartnerLimitReached => partnerLimit != -1 && partnersUsed >= partnerLimit;
  bool get isDailyBillLimitReached => dailyBillLimit != -1 && billsUsedToday >= dailyBillLimit;
}

class DummyPlanData extends ChangeNotifier {
  static final DummyPlanData _instance = DummyPlanData._internal();
  factory DummyPlanData() => _instance;
  DummyPlanData._internal();

  PlanState _activeState = PlanState.free;
  PlanState get activeState => _activeState;

  UserRole _currentRole = UserRole.admin;
  UserRole get currentRole => _currentRole;

  int _billsUsedToday = 7;
  int get billsUsedToday => _billsUsedToday;

  void setPlanState(PlanState newState) {
    _activeState = newState;
    notifyListeners();
  }

  void setCurrentRole(UserRole newRole) {
    _currentRole = newRole;
    notifyListeners();
  }

  void incrementBillsUsed() {
    _billsUsedToday++;
    notifyListeners();
  }

  bool get isDailyBillLimitReached => usage.dailyBillLimit != -1 && _billsUsedToday >= usage.dailyBillLimit;
  bool get isVehicleLimitReached => usage.vehicleLimit != -1 && usage.vehiclesUsed >= usage.vehicleLimit;
  bool get isPartnerLimitReached => usage.partnerLimit != -1 && usage.partnersUsed >= usage.partnerLimit;

  static const PlanModel freePlan = PlanModel(
    id: 'free',
    name: 'Free Starter Plan',
    pricePerMonth: 0,
    vehicleLimit: 5,
    partnerLimit: 2,
    dailyBillLimit: 10,
    staffUserLimit: 1,
    isCurrent: true,
    features: [
      'Up to 5 Vehicles',
      'Up to 2 Fleet Partners',
      '10 Daily Invoices / Bills',
      'Basic Rental Ledger',
      'Manual Receipts',
    ],
  );

  static const PlanModel starterPlan = PlanModel(
    id: 'starter',
    name: 'Growth Operator',
    pricePerMonth: 99,
    vehicleLimit: 25,
    partnerLimit: 10,
    dailyBillLimit: 50,
    staffUserLimit: 5,
    features: [
      'Up to 25 Vehicles',
      'Up to 10 Partners',
      '50 Daily Invoices',
      'WhatsApp Automation & Receipts',
      '5 Staff Accounts & Roles',
      'CSV Export Reports',
    ],
  );

  static const PlanModel proPlan = PlanModel(
    id: 'pro',
    name: 'Enterprise Mobility',
    pricePerMonth: 999,
    vehicleLimit: -1,
    partnerLimit: -1,
    dailyBillLimit: -1,
    staffUserLimit: -1,
    features: [
      'Unlimited Fleet Inventory',
      'Unlimited Fleet Partners',
      'Unlimited Daily Invoices',
      'GPS Auto-Sync & Cut-Off',
      'FASTag Toll Reconcilement',
      'Dedicated Account Manager',
    ],
  );

  static const List<PlanModel> allPlans = [
    freePlan,
    starterPlan,
    proPlan,
  ];

  PlanUsageData get usage => PlanUsageData(
        vehiclesUsed: 5,
        vehicleLimit: 5,
        partnersUsed: 2,
        partnerLimit: 2,
        billsUsedToday: _billsUsedToday,
        dailyBillLimit: 10,
        staffUsersUsed: 1,
        staffUserLimit: 1,
        isStaffLocked: _activeState == PlanState.free,
      );
}
