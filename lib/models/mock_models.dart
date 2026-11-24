import '../core/api_config.dart';

enum VehicleStatus { available, booked, inService, reserved, disabled }
enum BookingStatus { active, pending, completed, overdue, cancelled }
enum PartnerStatus { active, inactive, viewOnly }
enum RoleType { admin, manager, accountant, driver }

class Vehicle {
  final String id;
  final String name;
  final String regNumber;
  final String type; // car, bike
  final String category; // SUV, Sedan, Bike, Hatchback
  final String fuelType; // Petrol, Diesel, EV
  final String transmission; // Manual, Automatic
  final double dailyRate;
  final double hourlyRate;
  final double securityDeposit;
  final int odometerKm;
  final double fuelLevelPercent;
  final VehicleStatus status;
  final String imageUrl;
  final String assignedPartner;
  final String? partnerId;
  final double? partnerSharePercentage;
  final String color;
  final String year;
  final String? rcNumber;
  final String? rcExpiryDate;
  final String? rcImageUrl;
  final String? insuranceExpiryDate;
  final String? insurancePolicyNo;
  final String? insuranceImageUrl;
  final int totalBookings;

  bool get isBike {
    final t = type.toLowerCase();
    final c = category.toLowerCase();
    return t.contains('bike') || t.contains('two') || t.contains('scooter') ||
           c.contains('bike') || c.contains('two') || c.contains('scooter');
  }

  Vehicle({
    required this.id,
    required this.name,
    required this.regNumber,
    this.type = 'car',
    required this.category,
    required this.fuelType,
    required this.transmission,
    required this.dailyRate,
    required this.hourlyRate,
    required this.securityDeposit,
    required this.odometerKm,
    required this.fuelLevelPercent,
    required this.status,
    required this.imageUrl,
    this.assignedPartner = 'Direct Fleet',
    this.partnerId,
    this.partnerSharePercentage,
    this.color = 'White',
    this.year = '',
    this.rcNumber,
    this.rcExpiryDate,
    this.rcImageUrl,
    this.insuranceExpiryDate,
    this.insurancePolicyNo,
    this.insuranceImageUrl,
    this.totalBookings = 24,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString().toLowerCase() ?? 'available';
    VehicleStatus mappedStatus;
    switch (statusStr) {
      case 'rented':
      case 'booked':
        mappedStatus = VehicleStatus.booked;
        break;
      case 'maintenance':
      case 'inservice':
      case 'in_service':
        mappedStatus = VehicleStatus.inService;
        break;
      case 'disabled':
        mappedStatus = VehicleStatus.disabled;
        break;
      case 'reserved':
        mappedStatus = VehicleStatus.reserved;
        break;
      default:
        mappedStatus = VehicleStatus.available;
    }

    final daily = (json['daily_rate'] as num?)?.toDouble() ?? 2000.0;
    final rawImg = json['image_url']?.toString();
    final resolvedImg = ApiConfig.resolveImageUrl(rawImg);
    final fallbackImg = resolvedImg.isNotEmpty
        ? resolvedImg
        : 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&q=80&w=800';

    final rawRcImg = json['rc_image_url']?.toString();
    final rawInsImg = json['insurance_image_url']?.toString();

    final rawType = json['type']?.toString().toLowerCase() ?? 'car';
    final rawCategory = json['category']?.toString() ?? (rawType.contains('bike') ? 'Bike' : 'Car');
    final partnerObj = json['partner'] is Map ? json['partner'] as Map<String, dynamic> : null;
    final partnerShare = (json['partner_share_percentage'] as num?)?.toDouble() ??
        (partnerObj != null ? (partnerObj['share_percentage'] as num?)?.toDouble() : null);
    final partnerId = json['partner_id']?.toString() ?? partnerObj?['id']?.toString();

    return Vehicle(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Vehicle',
      regNumber: json['number']?.toString() ?? json['regNumber']?.toString() ?? '',
      type: rawType,
      category: rawCategory,
      fuelType: json['fuel_type']?.toString() ?? json['fuelType']?.toString() ?? 'Petrol',
      transmission: json['transmission']?.toString() ?? 'Manual',
      dailyRate: daily,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? (daily / 10),
      securityDeposit: (json['security_deposit'] as num?)?.toDouble() ?? 3000.0,
      odometerKm: (json['odometer'] as num?)?.toInt() ?? 0,
      fuelLevelPercent: (json['fuel_level_percent'] as num?)?.toDouble() ?? 100.0,
      status: mappedStatus,
      imageUrl: fallbackImg,
      assignedPartner: partnerObj != null ? (partnerObj['name']?.toString() ?? 'Direct Fleet') : 'Direct Fleet',
      partnerId: partnerId,
      partnerSharePercentage: partnerShare,
      color: json['color']?.toString() ?? 'White',
      year: json['year']?.toString() ?? '',
      rcNumber: json['rc_number']?.toString(),
      rcExpiryDate: json['rc_expiry_date']?.toString(),
      rcImageUrl: rawRcImg != null && rawRcImg.isNotEmpty ? ApiConfig.resolveImageUrl(rawRcImg) : null,
      insuranceExpiryDate: json['insurance_expiry_date']?.toString(),
      insurancePolicyNo: json['insurance_policy_no']?.toString(),
      insuranceImageUrl: rawInsImg != null && rawInsImg.isNotEmpty ? ApiConfig.resolveImageUrl(rawInsImg) : null,
      totalBookings: (json['total_bookings'] as num?)?.toInt() ?? 0,
    );
  }
}

class Booking {
  final String id;
  final String? bookingNumber;
  final String customerName;
  final String customerPhone;
  final String vehicleName;
  final String vehicleRegNumber;
  final DateTime startDate;
  final DateTime endDate;
  final double totalAmount;
  final double advancePaid;
  final double pendingAmount;
  final double securityDeposit;
  final BookingStatus status;
  final int startOdometer;
  final int? endOdometer;
  final String paymentMode;
  final String kycDocType;
  final String kycDocNumber;
  final String? vehicleId;
  final String? customerId;

  // Inspection and trip lifecycle data
  final DateTime? pickupAt;
  final DateTime? settledAt;
  final double? fuelLevelPercent;
  final String? pickupNotes;
  final Map<String, List<String>> pickupPhotos;
  final double? extraKmCharge;
  final double? fuelCharge;
  final double? damageDeduction;
  final double? finalSettlementAmount;

  String get displayId => (bookingNumber != null && bookingNumber!.isNotEmpty)
      ? bookingNumber!
      : (id.startsWith('BK-') ? id : 'BK-${id.padLeft(5, '0')}');

  int? get totalKmsDriven => (endOdometer != null && startOdometer > 0) ? (endOdometer! - startOdometer) : null;

  List<String> get allPickupPhotos {
    final list = <String>[];
    for (final entry in pickupPhotos.values) {
      list.addAll(entry);
    }
    return list;
  }

  bool get hasPickupInspection => startOdometer > 0 || allPickupPhotos.isNotEmpty || pickupAt != null;
  bool get hasReturnInspection => endOdometer != null || settledAt != null;

  Booking({
    required this.id,
    this.bookingNumber,
    required this.customerName,
    required this.customerPhone,
    required this.vehicleName,
    required this.vehicleRegNumber,
    required this.startDate,
    required this.endDate,
    required this.totalAmount,
    required this.advancePaid,
    required this.pendingAmount,
    required this.securityDeposit,
    required this.status,
    required this.startOdometer,
    this.endOdometer,
    required this.paymentMode,
    required this.kycDocType,
    required this.kycDocNumber,
    this.vehicleId,
    this.customerId,
    this.pickupAt,
    this.settledAt,
    this.fuelLevelPercent,
    this.pickupNotes,
    this.pickupPhotos = const {},
    this.extraKmCharge,
    this.fuelCharge,
    this.damageDeduction,
    this.finalSettlementAmount,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString().toLowerCase() ?? 'booked';
    BookingStatus mappedStatus;
    switch (statusStr) {
      case 'running':
      case 'active':
        mappedStatus = BookingStatus.active;
        break;
      case 'returned':
      case 'completed':
        mappedStatus = BookingStatus.completed;
        break;
      case 'overdue':
      case 'late':
        mappedStatus = BookingStatus.overdue;
        break;
      case 'cancelled':
        mappedStatus = BookingStatus.cancelled;
        break;
      default:
        mappedStatus = BookingStatus.pending;
    }

    // Vehicle extraction
    final vehicleObj = json['vehicle'] is Map ? json['vehicle'] as Map<String, dynamic> : null;
    final vehicleName = vehicleObj?['name']?.toString() ?? json['vehicle_name']?.toString() ?? 'Vehicle';
    final vehicleReg = vehicleObj?['number']?.toString() ?? json['vehicle_number']?.toString() ?? '';
    final vehicleDaily = (vehicleObj?['daily_rate'] as num?)?.toDouble() ?? 0.0;
    final vehicleDeposit = (vehicleObj?['security_deposit'] as num?)?.toDouble() ?? 0.0;
    final isBike = vehicleName.toLowerCase().contains('bike') ||
        vehicleName.toLowerCase().contains('enfield') ||
        vehicleName.toLowerCase().contains('hunter') ||
        vehicleName.toLowerCase().contains('activa') ||
        vehicleName.toLowerCase().contains('scooter');

    // Customer extraction
    final customerObj = json['customer'] is Map ? json['customer'] as Map<String, dynamic> : null;
    final customerName = customerObj?['name']?.toString() ?? json['customer_name']?.toString() ?? 'Customer';
    final customerMobile = customerObj?['mobile']?.toString() ?? json['customer_mobile']?.toString() ?? '';

    // Dates extraction
    final datesObj = json['dates'] is Map ? json['dates'] as Map<String, dynamic> : null;
    final startRaw = datesObj?['start_at'] ?? json['start_at'];
    final endRaw = datesObj?['end_at'] ?? json['end_at'];
    final pickupRaw = datesObj?['pickup_at'] ?? json['pickup_at'];
    final settledRaw = datesObj?['settled_at'] ?? json['settled_at'];

    final startDate = DateTime.tryParse(startRaw?.toString() ?? '') ?? DateTime.now();
    final endDate = DateTime.tryParse(endRaw?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 2));
    final pickupAt = DateTime.tryParse(pickupRaw?.toString() ?? '');
    final settledAt = DateTime.tryParse(settledRaw?.toString() ?? '');

    // Calculate duration in days (minimum 1 day)
    final diffHours = endDate.difference(startDate).inHours;
    final tripDays = diffHours > 0 ? (diffHours / 24).ceil().clamp(1, 365) : 1;

    // Financials extraction
    final finObj = json['financials'] is Map ? json['financials'] as Map<String, dynamic> : null;

    double amount = (finObj?['total_amount'] as num?)?.toDouble() ??
        (json['total_amount'] as num?)?.toDouble() ??
        (json['amount'] as num?)?.toDouble() ??
        0.0;

    double deposit = (finObj?['security_deposit'] as num?)?.toDouble() ??
        (json['security_deposit'] as num?)?.toDouble() ??
        0.0;

    double advance = (finObj?['advance_paid'] as num?)?.toDouble() ??
        (json['advance_paid'] as num?)?.toDouble() ??
        0.0;

    // Dynamic auto-calculate if amount is zero
    if (amount <= 0) {
      if (vehicleDaily > 0) {
        amount = vehicleDaily * tripDays;
      } else {
        amount = (isBike ? 800.0 : 2200.0) * tripDays;
      }
    }

    // Dynamic auto-calculate if security deposit is zero
    if (deposit <= 0) {
      if (vehicleDeposit > 0) {
        deposit = vehicleDeposit;
      } else {
        deposit = isBike ? 1500.0 : 3000.0;
      }
    }

    // Pending receivable calculation
    double pending = (finObj?['balance_due'] as num?)?.toDouble() ??
        (json['pending_amount'] as num?)?.toDouble() ??
        (amount - advance);
    if (pending < 0) pending = 0.0;

    // Inspection extraction
    final pickupObj = json['pickup_inspection'] is Map ? json['pickup_inspection'] as Map<String, dynamic> : null;
    final returnObj = json['return_inspection'] is Map ? json['return_inspection'] as Map<String, dynamic> : null;

    final startOdometer = (pickupObj?['odometer'] as num?)?.toInt() ??
        (json['start_odometer'] as num?)?.toInt() ??
        0;

    final endOdometer = (returnObj?['odometer'] as num?)?.toInt() ??
        (json['end_odometer'] as num?)?.toInt();

    final fuelLevelPercent = (pickupObj?['fuel_percent'] as num?)?.toDouble() ??
        (json['fuel_level_percent'] as num?)?.toDouble() ??
        100.0;

    final pickupNotes = pickupObj?['notes']?.toString() ?? json['pickup_notes']?.toString();

    // Parse pickup photos (Map<String, List<String>> or flat list)
    final Map<String, List<String>> parsedPhotos = {};
    final rawPhotos = pickupObj?['photos'] ?? json['pickup_photos'];
    if (rawPhotos is Map) {
      rawPhotos.forEach((key, val) {
        if (val is List) {
          final list = val.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
          if (list.isNotEmpty) parsedPhotos[key.toString()] = list;
        } else if (val is String && val.isNotEmpty) {
          parsedPhotos[key.toString()] = [val];
        }
      });
    } else if (rawPhotos is List) {
      final list = rawPhotos.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      if (list.isNotEmpty) parsedPhotos['Inspection Photos'] = list;
    }

    final extraKmCharge = (returnObj?['extra_km_charge'] as num?)?.toDouble() ??
        (finObj?['extra_km_charge'] as num?)?.toDouble() ??
        (json['extra_km_charge'] as num?)?.toDouble();

    final fuelCharge = (returnObj?['fuel_charge'] as num?)?.toDouble() ??
        (finObj?['fuel_charge'] as num?)?.toDouble() ??
        (json['fuel_charge'] as num?)?.toDouble();

    final damageDeduction = (returnObj?['damage_deduction'] as num?)?.toDouble() ??
        (finObj?['damage_deduction'] as num?)?.toDouble() ??
        (json['damage_deduction'] as num?)?.toDouble();

    final finalSettlement = (returnObj?['final_settlement'] as num?)?.toDouble() ??
        (finObj?['final_settlement'] as num?)?.toDouble() ??
        (json['final_amount'] as num?)?.toDouble();

    final paymentMode = finObj?['payment_mode']?.toString() ??
        json['payment_mode']?.toString() ??
        'UPI';

    final rawId = json['id']?.toString() ??
        json['order_no']?.toString() ??
        json['booking_id']?.toString() ??
        '';

    final bookingNumber = json['booking_id']?.toString() ??
        (rawId.startsWith('BK-') ? rawId : 'BK-${rawId.padLeft(5, '0')}');

    final vehicleId = json['vehicle_id']?.toString() ?? vehicleObj?['id']?.toString();
    final customerId = json['customer_id']?.toString() ?? customerObj?['id']?.toString();

    return Booking(
      id: rawId,
      bookingNumber: bookingNumber,
      customerName: customerName,
      customerPhone: customerMobile,
      vehicleName: vehicleName,
      vehicleRegNumber: vehicleReg,
      startDate: startDate,
      endDate: endDate,
      totalAmount: amount,
      advancePaid: advance,
      pendingAmount: pending,
      securityDeposit: deposit,
      status: mappedStatus,
      startOdometer: startOdometer,
      endOdometer: endOdometer,
      paymentMode: paymentMode,
      kycDocType: 'Aadhar Card',
      kycDocNumber: 'Verified',
      vehicleId: vehicleId,
      customerId: customerId,
      pickupAt: pickupAt,
      settledAt: settledAt,
      fuelLevelPercent: fuelLevelPercent,
      pickupNotes: pickupNotes,
      pickupPhotos: parsedPhotos,
      extraKmCharge: extraKmCharge,
      fuelCharge: fuelCharge,
      damageDeduction: damageDeduction,
      finalSettlementAmount: finalSettlement,
    );
  }
}

class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String drivingLicense;
  final String address;
  final int totalRentals;
  final double totalSpent;
  final double outstandingBalance;
  final String rating;
  final bool isVerified;
  bool isBlacklisted;
  String? blacklistReason;
  final String? dlImageUrl;
  final String? idProofImageUrl;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.drivingLicense,
    required this.address,
    required this.totalRentals,
    required this.totalSpent,
    required this.outstandingBalance,
    this.rating = '4.9 ★',
    this.isVerified = true,
    this.isBlacklisted = false,
    this.blacklistReason,
    this.dlImageUrl,
    this.idProofImageUrl,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['mobile']?.toString() ?? json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      drivingLicense: json['dl_no']?.toString() ?? 'OD02-DL-VERIFIED',
      address: json['address']?.toString() ?? 'Local',
      totalRentals: (json['total_bookings'] as num?)?.toInt() ?? (json['totalRentals'] as num?)?.toInt() ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
      outstandingBalance: (json['outstanding_balance'] as num?)?.toDouble() ?? 0.0,
      rating: '4.9 ★',
      isVerified: true,
      isBlacklisted: json['is_blacklisted'] == true,
      blacklistReason: json['blacklist_reason']?.toString(),
      dlImageUrl: json['dl_image_url']?.toString(),
      idProofImageUrl: json['id_proof_image_url']?.toString(),
    );
  }
}

class Partner {
  final String id;
  final String name;
  final String phone;
  final String email;
  final double profitSplitPercent;
  final int attachedVehiclesCount;
  final double totalEarned;
  final double pendingPayout;
  final PartnerStatus status;
  final String bankAccount;
  final String upiId;
  final String payoutType; // 'percentage' or 'fixed'
  final double fixedPayoutAmount;
  final String fixedPayoutFrequency; // 'Per Day', 'Per Week', 'Per Month'
  final List<String> assignedVehicleIds;

  Partner({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    required this.profitSplitPercent,
    this.attachedVehiclesCount = 0,
    this.totalEarned = 0.0,
    this.pendingPayout = 0.0,
    this.status = PartnerStatus.active,
    this.bankAccount = '',
    this.upiId = '',
    this.payoutType = 'percentage',
    this.fixedPayoutAmount = 0.0,
    this.fixedPayoutFrequency = 'Per Month',
    this.assignedVehicleIds = const [],
  });

  factory Partner.fromJson(Map<String, dynamic> json) {
    return Partner(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['mobile']?.toString() ?? json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profitSplitPercent: (json['share_value'] as num?)?.toDouble() ?? 70.0,
      attachedVehiclesCount: (json['vehicles_count'] as num?)?.toInt() ?? 0,
      totalEarned: (json['total_earned'] as num?)?.toDouble() ?? 0.0,
      pendingPayout: (json['balance'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] == 'inactive' ? PartnerStatus.inactive : PartnerStatus.active,
      bankAccount: json['bank_account']?.toString() ?? 'HDFC Bank •••• 9812',
      upiId: json['upi_id']?.toString() ?? '',
      payoutType: json['share_type']?.toString() ?? 'percentage',
      fixedPayoutAmount: 0.0,
      fixedPayoutFrequency: 'Per Month',
      assignedVehicleIds: const [],
    );
  }
}

class StoreProduct {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final double price;
  final double originalPrice;
  final String rating;
  final String imageUrl;
  final bool isPopular;
  final List<String> specs;

  StoreProduct({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.price,
    required this.originalPrice,
    required this.rating,
    required this.imageUrl,
    required this.isPopular,
    required this.specs,
  });

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    final price = (json['discount_price'] as num?)?.toDouble() ?? (json['price'] as num?)?.toDouble() ?? 0.0;
    final origPrice = (json['price'] as num?)?.toDouble() ?? price;
    final specsList = (json['features'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return StoreProduct(
      id: json['id']?.toString() ?? '',
      title: json['name']?.toString() ?? '',
      subtitle: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Hardware',
      price: price,
      originalPrice: origPrice,
      rating: '4.9 ★',
      imageUrl: json['image_url']?.toString() ??
          'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&q=80&w=800',
      isPopular: json['flash_on_dashboard'] == true,
      specs: specsList,
    );
  }
}

class StaffUser {
  final String id;
  final String name;
  final String phone;
  final RoleType role;
  final String avatarUrl;
  final bool isActive;
  final DateTime lastActive;

  StaffUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.avatarUrl,
    required this.isActive,
    required this.lastActive,
  });

  factory StaffUser.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role']?.toString().toLowerCase() ?? 'staff';
    RoleType mappedRole;
    switch (roleStr) {
      case 'admin':
        mappedRole = RoleType.admin;
        break;
      case 'manager':
        mappedRole = RoleType.manager;
        break;
      case 'driver':
        mappedRole = RoleType.driver;
        break;
      default:
        mappedRole = RoleType.accountant;
    }

    return StaffUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['mobile']?.toString() ?? json['phone']?.toString() ?? '',
      role: mappedRole,
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=400',
      isActive: json['is_active'] != false,
      lastActive: DateTime.tryParse(json['last_login_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

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
