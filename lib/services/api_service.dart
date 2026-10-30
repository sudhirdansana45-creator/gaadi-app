import 'dart:io';
import '../core/api_config.dart';
import 'api_client.dart';

class ApiService {
  final ApiClient _client = ApiClient();

  // ==================== AUTH ====================
  Future<dynamic> login(String mobile, String password) async {
    return await _client.post(ApiConfig.login, body: {
      'mobile': mobile,
      'password': password,
    });
  }

  Future<dynamic> verifyOtp(String mobile, String otp) async {
    return await _client.post(ApiConfig.verifyOtp, body: {
      'mobile': mobile,
      'otp': otp,
    });
  }

  Future<dynamic> register({
    required String name,
    required String mobile,
    required String password,
    String? email,
    String? businessName,
    String? city,
  }) async {
    return await _client.post(ApiConfig.register, body: {
      'name': name,
      'mobile': mobile,
      'password': password,
      if (email != null && email.isNotEmpty) 'email': email,
      'business_name': businessName,
      'city': city,
    });
  }

  Future<dynamic> forgotPin(String mobile) async {
    return await _client.post(ApiConfig.forgotPin, body: {
      'mobile': mobile,
    });
  }

  Future<dynamic> resetPin({
    required String mobile,
    required String otp,
    required String pin,
  }) async {
    return await _client.post(ApiConfig.resetPin, body: {
      'mobile': mobile,
      'otp': otp,
      'pin': pin,
    });
  }

  Future<dynamic> getProfile() async {
    return await _client.get(ApiConfig.profile);
  }

  Future<dynamic> logout() async {
    try {
      await _client.post(ApiConfig.logout);
    } finally {
      await _client.clearSession();
    }
  }

  Future<dynamic> updateDeviceToken(String fcmToken, String platform) async {
    return await _client.post(ApiConfig.deviceToken, body: {
      'fcm_token': fcmToken,
      'platform': platform,
    });
  }

  // ==================== DASHBOARD ====================
  Future<dynamic> getDashboardStats() async {
    return await _client.get(ApiConfig.dashboardStats);
  }

  // ==================== VEHICLES ====================
  Future<dynamic> getVehicles({String? status, String? category, String? search}) async {
    return await _client.get(ApiConfig.vehicles, queryParams: {
      if (status != null && status.isNotEmpty) 'status': status,
      if (category != null && category.isNotEmpty) 'category': category,
      if (search != null && search.isNotEmpty) 'search': search,
    });
  }

  Future<dynamic> getVehicleDetail(String id) async {
    return await _client.get(ApiConfig.vehicleDetail(id));
  }

  Future<dynamic> createVehicle({
    required Map<String, String> fields,
    Map<String, File>? images,
  }) async {
    return await _client.postMultipart(ApiConfig.vehicles, fields: fields, files: images);
  }

  Future<dynamic> updateVehicle(String id, Map<String, dynamic> data) async {
    return await _client.put(ApiConfig.vehicleDetail(id), body: data);
  }

  Future<dynamic> updateVehicleStatus(String id, String status) async {
    return await _client.patch(ApiConfig.vehicleStatus(id), body: {'status': status});
  }

  // ==================== BOOKINGS ====================
  Future<dynamic> getBookings({String? status, String? search}) async {
    return await _client.get(ApiConfig.bookings, queryParams: {
      if (status != null && status.isNotEmpty) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    });
  }

  Future<dynamic> getBookingDetail(String id) async {
    return await _client.get(ApiConfig.bookingDetail(id));
  }

  Future<dynamic> createBooking(Map<String, dynamic> bookingData) async {
    return await _client.post(ApiConfig.bookings, body: bookingData);
  }

  Future<dynamic> submitPickupInspection(String id, {
    required int startOdometer,
    required double fuelPercent,
    required String notes,
    Map<String, File>? photos,
  }) async {
    return await _client.postMultipart(
      ApiConfig.bookingPickup(id),
      fields: {
        'start_odometer': startOdometer.toString(),
        'fuel_level_percent': fuelPercent.toString(),
        'pickup_notes': notes,
      },
      files: photos,
    );
  }

  Future<dynamic> extendBooking(String id, {
    required String newEndDate,
    required double extraAmount,
  }) async {
    return await _client.post(ApiConfig.bookingExtend(id), body: {
      'new_end_date': newEndDate,
      'extra_amount': extraAmount,
    });
  }

  Future<dynamic> returnSettlement(String id, {
    required int endOdometer,
    required double extraKmCharge,
    required double fuelCharge,
    required double damageDeduction,
    required double finalSettlementAmount,
    required String paymentMode,
  }) async {
    return await _client.post(ApiConfig.bookingReturn(id), body: {
      'end_odometer': endOdometer,
      'extra_km_charge': extraKmCharge,
      'fuel_charge': fuelCharge,
      'damage_deduction': damageDeduction,
      'final_amount': finalSettlementAmount,
      'payment_mode': paymentMode,
    });
  }

  Future<dynamic> recordBookingPayment(String id, {
    required double amount,
    required String paymentMode,
    String? transactionRef,
  }) async {
    return await _client.post(ApiConfig.bookingPayment(id), body: {
      'amount': amount,
      'payment_mode': paymentMode,
      'reference_id': ?transactionRef,
    });
  }

  Future<dynamic> cancelBooking(String id, {
    required String reason,
    double refundAmount = 0.0,
  }) async {
    return await _client.post(ApiConfig.bookingCancel(id), body: {
      'reason': reason,
      'refund_amount': refundAmount,
    });
  }

  // ==================== CUSTOMERS ====================
  Future<dynamic> getCustomers({String? search}) async {
    return await _client.get(ApiConfig.customers, queryParams: {
      if (search != null && search.isNotEmpty) 'search': search,
    });
  }

  Future<dynamic> getCustomerDetail(String id) async {
    return await _client.get(ApiConfig.customerDetail(id));
  }

  Future<dynamic> createCustomer({
    required Map<String, String> fields,
    Map<String, File>? kycFiles,
  }) async {
    return await _client.postMultipart(ApiConfig.customers, fields: fields, files: kycFiles);
  }

  Future<dynamic> toggleCustomerBlacklist(String id, {required bool isBlacklisted, String? reason}) async {
    return await _client.patch(ApiConfig.customerBlacklist(id), body: {
      'is_blacklisted': isBlacklisted,
      'reason': ?reason,
    });
  }

  // ==================== PARTNERS ====================
  Future<dynamic> getPartners() async {
    return await _client.get(ApiConfig.partners);
  }

  Future<dynamic> getPartnerDetail(String id) async {
    return await _client.get(ApiConfig.partnerDetail(id));
  }

  Future<dynamic> createPartner(Map<String, dynamic> data) async {
    return await _client.post(ApiConfig.partners, body: data);
  }

  Future<dynamic> updatePartner(String id, Map<String, dynamic> data) async {
    return await _client.put(ApiConfig.partnerDetail(id), body: data);
  }

  Future<dynamic> getPartnerLedger(String id) async {
    return await _client.get(ApiConfig.partnerLedger(id));
  }

  Future<dynamic> recordPartnerPayout(String id, {
    required double amount,
    required String mode,
    String? note,
  }) async {
    return await _client.post(ApiConfig.partnerPayout(id), body: {
      'amount': amount,
      'payout_mode': mode,
      'note': ?note,
    });
  }

  // ==================== STORE ====================
  Future<dynamic> getStoreProducts({String? category}) async {
    return await _client.get(ApiConfig.storeProducts, queryParams: {
      if (category != null && category.isNotEmpty) 'category': category,
    });
  }

  Future<dynamic> getStoreProductDetail(String id) async {
    return await _client.get(ApiConfig.storeProductDetail(id));
  }

  Future<dynamic> placeStoreOrder({
    required String productId,
    required int quantity,
    required String shippingAddress,
    required String contactPhone,
  }) async {
    return await _client.post(ApiConfig.storeOrders, body: {
      'product_id': productId,
      'quantity': quantity,
      'shipping_address': shippingAddress,
      'contact_phone': contactPhone,
    });
  }

  // ==================== SUBSCRIPTION & PLANS ====================
  Future<dynamic> getPlans() async {
    return await _client.get(ApiConfig.plans);
  }

  Future<dynamic> getMySubscription() async {
    return await _client.get(ApiConfig.mySubscription);
  }

  Future<dynamic> requestPlanUpgrade(String planId) async {
    return await _client.post(ApiConfig.upgradeRequest, body: {
      'plan_id': planId,
    });
  }

  // ==================== STAFF ====================
  Future<dynamic> getStaffUsers() async {
    return await _client.get(ApiConfig.staff);
  }

  Future<dynamic> createStaffUser({
    required String name,
    required String phone,
    required String role,
  }) async {
    return await _client.post(ApiConfig.staff, body: {
      'name': name,
      'phone': phone,
      'role': role,
    });
  }

  Future<dynamic> toggleStaffStatus(String id, bool isActive) async {
    return await _client.patch(ApiConfig.staffToggle(id), body: {
      'is_active': isActive,
    });
  }

  // ==================== APP CONFIG & SETTINGS ====================
  Future<dynamic> checkAppVersion({required String platform, required String currentVersion}) async {
    return await _client.get(ApiConfig.versionCheck, queryParams: {
      'platform': platform,
      'version': currentVersion,
    });
  }

  Future<dynamic> getAppSettings() async {
    return await _client.get(ApiConfig.appConfig);
  }

  Future<dynamic> getReportsSummary({String? period}) async {
    return await _client.get(ApiConfig.reportsSummary, queryParams: {
      'period': ?period,
    });
  }

  Future<dynamic> getReportsVehicleWise() async {
    return await _client.get(ApiConfig.reportsVehicleWise);
  }
}
