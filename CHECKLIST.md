# Gaadi Manager - Dynamic Migration & Elimination of Static Data Checklist

This checklist tracks the systematic elimination of all static, mock, and dummy data across the entire Flutter application (`/Users/sudhirdansana/Desktop/gaadi_manager/flutter`), replacing them with live Laravel REST API calls and clean "Not Found" / Empty States.

---

## 📋 Module-Wise Audit & Migration Status

### 1. Dashboard Module (`lib/screens/dashboard/`)
- [x] **Home Dashboard Greeting**: Dynamic operator name & business name from live auth session / `/dashboard/stats` (Removed hardcoded "Rajesh" and "Royal Rentals").
- [x] **Today's Pulse Cards**: Dynamic revenue (`today_revenue`), pending due (`pending_due`), pending invoices count, active on road, and available depot count.
- [x] **Daily Invoice Quota**: Strictly dynamic from `/dashboard/stats` `quota` (Removed hardcoded fallback of 7 and 10).
- [x] **Offer / Promo Banner**: Dynamic from `flash_products` API (Removed hardcoded ₹1,499 / ₹2,299).
- [x] **Priority Returns Section**: Dynamic from `recent_bookings` with verified empty state (Removed dummy bookings).
- [x] **Garage Stat Strip**: Dynamic depot city from operator profile (Removed hardcoded "Sector 18").

---

### 2. Vehicles Fleet Module (`lib/screens/vehicles/`)
- [x] **Vehicles List Screen (`vehicles_list_screen.dart`)**:
  - [x] Fetch live fleet from `ApiService().getVehicles()`.
  - [x] Remove `MockData.vehicles` fallback when list is empty.
  - [x] Add clean "No Vehicles in Fleet / Not Found" empty state with "+ Add Vehicle" button.
  - [x] Fix Hero tag collision on FloatingActionButton (`heroTag: null`).
- [x] **Add / Edit Vehicle Screen (`add_vehicle_screen.dart`)**:
  - [x] Call `ApiService().createVehicle(...)` / update API.
  - [x] Remove `_insertLocalVehicle()` fallback into `MockData.vehicles`.
  - [x] Display real backend validation error message when vehicle limit is reached or fields are invalid.
  - [x] Removed static prepopulated controller strings.

---

### 3. Bookings Lifecycle Module (`lib/screens/bookings/`)
- [x] **Bookings List Screen (`bookings_list_screen.dart`)**:
  - [x] Fetch live bookings from `ApiService().getBookings()`.
  - [x] Remove `MockData.bookings` fallback when list is empty.
  - [x] Clean empty state when 0 bookings found.
  - [x] Fix Hero tag collision on FloatingActionButton (`heroTag: null`).
  - [x] Fix `ListTile` background color ink splash warning.
- [x] **New Booking Screen (`new_booking_screen.dart`)**:
  - [x] Fix `DropdownButtonFormField<Vehicle>` RenderFlex horizontal overflow (11px).
  - [x] Remove all mock fallback lists for vehicles and customers.
  - [x] Handle clean empty states when no vehicles exist.
- [x] **Booking Detail Screen (`booking_detail_screen.dart`)**:
  - [x] Fetch live booking details via `ApiService().getBookingDetail(id)`.
  - [x] Remove `orElse: () => Booking(customerName: 'Rahul Verma', vehicleName: 'Mahindra Thar'...)`.
  - [x] Display clean "Booking Not Found" state if booking ID does not exist in backend.
- [x] **Pickup Checklist Screen (`pickup_checklist_screen.dart`)**:
  - [x] Remove hardcoded start odometer text ('24500').
  - [x] Load vehicle's real current odometer from booking.
  - [x] Submit real pickup inspection to API.
- [x] **Return & Final Bill Screen (`return_final_bill_screen.dart`)**:
  - [x] Remove hardcoded end odometer ('24850'), damage ('1500'), and fallback amounts (₹7000 / ₹5000).
  - [x] Calculate settlement using real booking numbers; handle null booking with "Booking Not Found".
- [x] **Collect Payment Screen (`collect_payment_screen.dart`)**:
  - [x] Remove hardcoded amount ('4000') and transaction reference ('UPI-9920192831').
  - [x] Initialize amount with real booking `pendingAmount`.

---

### 4. Customers & KYC Module (`lib/screens/customers/`)
- [x] **Customers List Screen (`customers_list_screen.dart`)**:
  - [x] Fetch live customers from `ApiService().getCustomers()`.
  - [x] Remove `MockData.customers` fallback when list is empty.
  - [x] Add clean "No Customers Found" empty state with "Add Customer" prompt.
- [x] **Customer Profile Screen (`customer_profile_screen.dart`)**:
  - [x] Fetch live customer details and their real bookings from API.
  - [x] Remove fallback mock bookings (BK-1052 Mahindra Thar).
  - [x] Show clean "No booking history for this customer" when empty.

---

### 5. Partners & Investor Fleet Module (`lib/screens/partners/`)
- [x] **Partners List Screen (`partners_list_screen.dart`)**:
  - [x] Fetch live partners from `ApiService().getPartners()`.
  - [x] Remove `MockData.partners` fallback when list is empty.
  - [x] Add clean "No Partners Found" empty state.
  - [x] Replace `DummyPlanData().usage.isPartnerLimitReached` with real backend quota.
- [x] **Add / Edit Partner Screen (`add_edit_partner_screen.dart`)**:
  - [x] Fetch live vehicles for assignment instead of `MockData.vehicles`.
  - [x] Remove `MockData.partners.add(...)` fallback in catch block; display real API error.
- [x] **Partner Ledger Screen (`partner_ledger_screen.dart`)**:
  - [x] Fetch live ledger transactions from `ApiService().getPartnerLedger(partnerId)`.
  - [x] Remove hardcoded fake transaction rows (Mahindra Thar trip share, HDFC payout, Royal Enfield trip share).
  - [x] Show clean "No transactions found in partner ledger" when empty.

---

### 6. Hardware Store Module (`lib/screens/store/`)
- [x] **Store Catalog Screen (`store_screen.dart`)**:
  - [x] Fetch live products from `ApiService().getStoreProducts()`.
  - [x] Remove `_products = List.from(MockData.storeProducts)` initialization and fallback.
  - [x] Add clean "No products available in store" empty state.
- [x] **Product Detail / Enquiry (`product_detail_enquiry_screen.dart`)**:
  - [x] Use live user profile for enquiry autofill (Already integrated).
  - [x] Fetch product details dynamically via `productId` and show clean Product Not Found screen if missing.

---

### 7. Reports & Analytics Module (`lib/screens/reports/`)
- [x] **Reports Hub Screen (`reports_hub_screen.dart`)**:
  - [x] Fetch active subscription plan from backend to determine report feature locks.
- [x] **Daily & Monthly Report Screen (`daily_monthly_report_screen.dart`)**:
  - [x] Remove hardcoded dummy chart data (`_dailyChartData`, `_monthlyChartData`).
  - [x] Fetch live data from `ApiService().getReportsSummary(period)`.
  - [x] Show real gross revenue, advance collected, net income, or zero/empty state.
- [x] **Vehicle-Wise Report Screen (`vehicle_wise_report_screen.dart`)**:
  - [x] Remove hardcoded ₹84,000 monthly revenue, 24/30 days, ₹4,500 maintenance.
  - [x] Fetch live performance data from `ApiService().getReportsVehicleWise()`.
  - [x] Show clean "No vehicle performance records found" when empty.

---

### 8. Settings & Platform Tools (`lib/screens/settings/`)
- [x] **Settings Screen (`settings_screen.dart`)**:
  - [x] Dynamic profile card from `ApiClient.userNotifier` (Removed "Rajesh Fleet Mobility").
  - [x] Dynamic plan status from backend subscription (`ApiClient().currentUser['plan']`).
  - [x] Dynamic tool locks & subtitles based on subscription plan.
- [x] **Plans and Usage Screen (`plans_and_usage_screen.dart`)**:
  - [x] Remove hardcoded usage counts (7 bills today, 5 vehicles limit, etc.).
  - [x] Fetch live subscription and quota from `/subscription/my-plan` and available plans from `/plans`.
  - [x] Integrated real plan upgrade request API (`ApiService().requestPlanUpgrade()`).
- [x] **Users & Roles Screen (`users_and_roles_screen.dart`)**:
  - [x] Dynamic admin profile from `ApiClient.currentUser` (Removed "Rajesh Sharma").
  - [x] Fetch live staff list from `ApiService().getStaffUsers()`.
  - [x] Dynamic staff limit quota from active subscription plan.
  - [x] Remove hardcoded mock staff accounts ("Anil Kumar", "Manoj Singh").
- [x] **WhatsApp Automation & Wallet (`whatsapp_templates_wallet_screen.dart`)**:
  - [x] Remove hardcoded "1,420 Credits" balance (now shows real balance '0 Credits Available' until recharged).
  - [x] Remove fake preview names ("Rahul Verma", "Mahindra Thar"); dynamic placeholder previews instead.
  - [x] Remove hardcoded mock message dispatch log; verified "No WhatsApp Message Logs" empty state.

---

### 9. Navigation & Router (`lib/core/router.dart`)
- [x] Removed `mock_data.dart` and `dummy_plan_data.dart` imports from router and plan guards.
- [x] Removed all `orElse: () => MockData.*.first` fallbacks across all deep link route handlers.
- [x] Replaced `'BK-1089'` routing fallbacks with clean dynamic id handling; all detail screens handle missing items by rendering dedicated "Not Found" / Empty State UIs.
- [x] Fixed Hero tag collisions across all floating action buttons (`heroTag: null`).
- [x] `flutter analyze lib/` passes with 0 errors and 0 warnings.

---

## 🎯 Verification & Sign-off Summary
- **Static Mock Data Removed**: 100% eliminated from active Flutter codebase (`flutter/lib/`).
- **Empty States Implemented**: Every list and detail screen displays a verified "Not Found" or empty state with user guidance.
- **Backend Sync**: Live Laravel endpoints connected for Auth, Dashboard, Bookings, Vehicles, Customers, Partners, Store, Reports, and Subscriptions.
- **Flutter Code Health**: `flutter analyze lib/` -> **No issues found!**

