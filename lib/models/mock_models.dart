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
    required this.email,
    required this.profitSplitPercent,
    required this.attachedVehiclesCount,
    required this.totalEarned,
    required this.pendingPayout,
    required this.status,
    required this.bankAccount,
    required this.upiId,
    this.payoutType = 'percentage',
    this.fixedPayoutAmount = 0.0,
    this.fixedPayoutFrequency = 'Per Month',
    this.assignedVehicleIds = const [],
  });
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
}
