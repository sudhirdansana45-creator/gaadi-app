class AppRoutes {
  // Auth
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPin = '/forgot-pin';

  // Tabs (Root branches)
  static const String home = '/home';
  static const String bookings = '/bookings';
  static const String vehicles = '/vehicles';
  static const String reports = '/reports';
  static const String more = '/more';

  // Bookings Flow
  static const String newBooking = '/bookings/new';
  static const String bookingDetail = '/bookings/:id';
  static const String pickupChecklist = '/bookings/:id/pickup';
  static const String returnFinalBill = '/bookings/:id/return';
  static const String collectPayment = '/bookings/:id/payment';

  // Vehicles Flow
  static const String addVehicle = '/vehicles/add';
  static const String editVehicle = '/vehicles/:id/edit';

  // Customers Flow
  static const String customers = '/customers';
  static const String addCustomer = '/customers/add';
  static const String customerDetail = '/customers/:id';
  static const String editCustomer = '/customers/:id/edit';

  // Partners Flow
  static const String partners = '/partners';
  static const String addPartner = '/partners/add';
  static const String editPartner = '/partners/:id/edit';
  static const String partnerLedger = '/partners/:id/ledger';

  // Reports Flow
  static const String dailyMonthlyReport = '/reports/daily-monthly';
  static const String vehicleWiseReport = '/reports/vehicle-wise';
  static const String ledgerWiseReport = '/reports/ledger-wise';
  static const String maintenanceReport = '/reports/maintenance';
  static const String partnerPayoutReport = '/reports/partner-payout';

  // Plans & Store
  static const String plans = '/plans';
  static const String store = '/store';
  static const String productDetail = '/store/product/:id';

  // Settings & WhatsApp & Users
  static const String usersAndRoles = '/settings/users';
  static const String whatsappTemplates = '/settings/whatsapp';
  static const String whatsappLog = '/settings/whatsapp/log';
  static const String businessProfile = '/settings/business-profile';
  static const String billingRules = '/settings/billing-rules';
  static const String invoiceFormat = '/settings/invoice-format';
  static const String helpSupport = '/settings/help';
  static const String privacyData = '/settings/privacy-data';
}
