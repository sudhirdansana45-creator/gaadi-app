enum VehicleStatus { available, booked, inService, reserved, disabled }
enum BookingStatus { active, pending, completed, overdue, cancelled }
enum PartnerStatus { active, inactive, viewOnly }
enum RoleType { admin, manager, accountant, driver }

class Vehicle {
  final String id;
  final String name;
  final String regNumber;
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
  final String color;
  final int totalBookings;

  Vehicle({
    required this.id,
    required this.name,
    required this.regNumber,
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
    this.color = 'White',
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
    return Vehicle(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Vehicle',
      regNumber: json['number']?.toString() ?? json['regNumber']?.toString() ?? '',
      category: json['category']?.toString() ?? (json['type']?.toString().toUpperCase() ?? 'Car'),
      fuelType: json['fuel_type']?.toString() ?? json['fuelType']?.toString() ?? 'Petrol',
      transmission: json['transmission']?.toString() ?? 'Manual',
      dailyRate: daily,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? (daily / 10),
      securityDeposit: (json['security_deposit'] as num?)?.toDouble() ?? 3000.0,
      odometerKm: (json['odometer'] as num?)?.toInt() ?? 0,
      fuelLevelPercent: (json['fuel_level_percent'] as num?)?.toDouble() ?? 100.0,
      status: mappedStatus,
      imageUrl: json['image_url']?.toString() ??
          'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&q=80&w=800',
      assignedPartner: json['partner'] is Map ? (json['partner']['name']?.toString() ?? 'Direct Fleet') : 'Direct Fleet',
      color: json['color']?.toString() ?? 'White',
      totalBookings: (json['total_bookings'] as num?)?.toInt() ?? 0,
    );
  }
}

class Booking {
  final String id;
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

  Booking({
    required this.id,
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

    final amount = (json['amount'] as num?)?.toDouble() ?? 0.0;
    final advance = (json['advance_paid'] as num?)?.toDouble() ?? 0.0;

    return Booking(
      id: json['order_no']?.toString() ?? json['id']?.toString() ?? '',
      customerName: json['customer'] is Map
          ? (json['customer']['name']?.toString() ?? '')
          : (json['customer_name']?.toString() ?? 'Customer'),
      customerPhone: json['customer'] is Map
          ? (json['customer']['mobile']?.toString() ?? '')
          : (json['customer_mobile']?.toString() ?? ''),
      vehicleName: json['vehicle'] is Map
          ? (json['vehicle']['name']?.toString() ?? '')
          : (json['vehicle_name']?.toString() ?? 'Vehicle'),
      vehicleRegNumber: json['vehicle'] is Map
          ? (json['vehicle']['number']?.toString() ?? '')
          : (json['vehicle_number']?.toString() ?? ''),
      startDate: DateTime.tryParse(json['start_at']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['end_at']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 2)),
      totalAmount: amount,
      advancePaid: advance,
      pendingAmount: (json['pending_amount'] as num?)?.toDouble() ?? (amount - advance),
      securityDeposit: (json['security_deposit'] as num?)?.toDouble() ?? 0.0,
      status: mappedStatus,
      startOdometer: (json['start_odometer'] as num?)?.toInt() ?? 0,
      endOdometer: (json['end_odometer'] as num?)?.toInt(),
      paymentMode: json['payment_mode']?.toString() ?? 'UPI',
      kycDocType: 'Aadhar Card',
      kycDocNumber: 'Verified',
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
