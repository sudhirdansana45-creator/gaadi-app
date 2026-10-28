import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'routes.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/auth/forgot_pin_screen.dart';
import '../screens/dashboard/home_dashboard_screen.dart';
import '../screens/bookings/bookings_list_screen.dart';
import '../screens/bookings/new_booking_screen.dart';
import '../screens/bookings/booking_detail_screen.dart';
import '../screens/bookings/pickup_checklist_screen.dart';
import '../screens/bookings/return_final_bill_screen.dart';
import '../screens/bookings/collect_payment_screen.dart';
import '../screens/vehicles/vehicles_list_screen.dart';
import '../screens/vehicles/add_vehicle_screen.dart';
import '../screens/customers/customers_list_screen.dart';
import '../screens/customers/customer_profile_screen.dart';
import '../screens/partners/partners_list_screen.dart';
import '../screens/partners/add_edit_partner_screen.dart';
import '../screens/partners/partner_ledger_screen.dart';
import '../screens/reports/reports_hub_screen.dart';
import '../screens/reports/daily_monthly_report_screen.dart';
import '../screens/reports/vehicle_wise_report_screen.dart';
import '../screens/settings/plans_and_usage_screen.dart';
import '../screens/store/store_screen.dart';
import '../screens/store/product_detail_enquiry_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/users_and_roles_screen.dart';
import '../screens/settings/whatsapp_templates_wallet_screen.dart';
import '../screens/common/coming_soon_screen.dart';
import '../widgets/app_bottom_nav.dart';
import '../core/plan_guard.dart';
import '../screens/modals/daily_limit_modal.dart';
import '../services/api_client.dart';
import '../data/mock_data.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: ApiClient().isAuthenticated ? AppRoutes.home : AppRoutes.login,
  refreshListenable: ApiClient.authStateNotifier,
  redirect: (context, state) {
    final bool loggedIn = ApiClient().isAuthenticated;
    final String loc = state.matchedLocation;
    final bool isAuthRoute = loc == AppRoutes.login ||
        loc == AppRoutes.signup ||
        loc == AppRoutes.forgotPin;

    // If not logged in and trying to access a protected screen, redirect to login
    if (!loggedIn && !isAuthRoute) {
      return AppRoutes.login;
    }

    // If already authenticated and trying to access login or signup, redirect to home
    if (loggedIn && (loc == AppRoutes.login || loc == AppRoutes.signup)) {
      return AppRoutes.home;
    }

    return null;
  },
  routes: [
    // Auth Routes
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => LoginScreen(
        onLogin: () => context.go(AppRoutes.home),
        onSignUp: () => context.push(AppRoutes.signup),
        onForgotPin: () => context.push(AppRoutes.forgotPin),
      ),
    ),
    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) => SignUpScreen(
        onSignUp: () => context.go(AppRoutes.home),
        onLogin: () => context.go(AppRoutes.login),
      ),
    ),
    GoRoute(
      path: AppRoutes.forgotPin,
      builder: (context, state) => ForgotPinScreen(
        onBackToLogin: () => context.go(AppRoutes.login),
        onResetSuccess: () => context.go(AppRoutes.login),
      ),
    ),

    // Shell Route for 5 Bottom-Nav Tabs
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: AppBottomNav(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            onQuickBooking: () {
              if (!PlanGuard.canCreateBill()) {
                DailyLimitModal.show(
                  context: context,
                  onUpgrade: () {
                    context.push(AppRoutes.plans);
                  },
                );
              } else {
                context.push(AppRoutes.newBooking);
              }
            },
          ),
        );
      },
      branches: [
        // Tab 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => HomeDashboardScreen(
                onNavigate: (route, {dynamic args}) {
                  if (route == 'bookings') {
                    context.go(AppRoutes.bookings);
                  } else if (route == 'daily_monthly_report') {
                    context.push(AppRoutes.dailyMonthlyReport);
                  } else if (route == 'customers') {
                    context.push(AppRoutes.customers);
                  } else if (route == 'vehicles') {
                    context.go(AppRoutes.vehicles);
                  } else if (route == 'store') {
                    context.push(AppRoutes.store);
                  } else if (route == 'plans') {
                    context.push(AppRoutes.plans);
                  } else if (route == 'booking_detail' && args != null) {
                    context.push('/bookings/$args');
                  } else if (route == 'product_detail' && args != null) {
                    context.push('/store/product/$args');
                  } else {
                    context.push(route);
                  }
                },
              ),
            ),
          ],
        ),

        // Tab 1: Bookings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.bookings,
              builder: (context, state) {
                final filter = state.uri.queryParameters['filter'];
                return BookingsListScreen(initialFilter: filter);
              },
            ),
          ],
        ),

        // Tab 2: Vehicles
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.vehicles,
              builder: (context, state) => VehiclesListScreen(
                onNavigate: (route, {dynamic args}) {
                  if (route == 'add_vehicle') {
                    context.push(AppRoutes.addVehicle);
                  } else if (route == 'plans') {
                    context.push(AppRoutes.plans);
                  } else if (args != null) {
                    context.push('/vehicles/$args/edit');
                  }
                },
              ),
            ),
          ],
        ),

        // Tab 3: Reports
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.reports,
              builder: (context, state) => ReportsHubScreen(
                onNavigate: (route, {dynamic args}) {
                  if (route == 'daily_monthly_report') {
                    context.push(AppRoutes.dailyMonthlyReport);
                  } else if (route == 'vehicle_wise_report') {
                    context.push(AppRoutes.vehicleWiseReport);
                  } else if (route == 'partner_ledger') {
                    context.push(AppRoutes.partners);
                  } else if (route == 'plans') {
                    context.push(AppRoutes.plans);
                  } else if (route == 'maintenance_report') {
                    context.push(AppRoutes.maintenanceReport);
                  } else if (route == 'gst_report') {
                    context.push(AppRoutes.ledgerWiseReport);
                  }
                },
              ),
            ),
          ],
        ),

        // Tab 4: More / Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.more,
              builder: (context, state) => SettingsScreen(
                onNavigate: (route, {dynamic args}) {
                  if (route == 'plans_and_usage' || route == 'plans') {
                    context.push(AppRoutes.plans);
                  } else if (route == 'whatsapp_wallet') {
                    context.push(AppRoutes.whatsappTemplates);
                  } else if (route == 'users_and_roles') {
                    context.push(AppRoutes.usersAndRoles);
                  } else if (route == 'customers') {
                    context.push(AppRoutes.customers);
                  } else if (route == 'partners') {
                    context.push(AppRoutes.partners);
                  } else if (route == 'store') {
                    context.push(AppRoutes.store);
                  } else if (route == 'business_profile') {
                    context.push(AppRoutes.businessProfile);
                  } else if (route == 'billing_rules') {
                    context.push(AppRoutes.billingRules);
                  } else if (route == 'invoice_format') {
                    context.push(AppRoutes.invoiceFormat);
                  } else if (route == 'help') {
                    context.push(AppRoutes.helpSupport);
                  } else {
                    context.push(route);
                  }
                },
                onLogout: () => context.go(AppRoutes.login),
              ),
            ),
          ],
        ),
      ],
    ),

    // Full-screen Push Routes (No Bottom-Nav)
    GoRoute(
      path: AppRoutes.newBooking,
      builder: (context, state) {
        return NewBookingScreen(
          onBookingCreated: () {
            context.pushReplacement('/bookings/BK-1089');
          },
          onCancel: () => context.pop(),
        );
      },
    ),
    GoRoute(
      path: '/bookings/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'BK-1089';
        return BookingDetailScreen(
          bookingId: id,
          onBack: () => context.pop(),
          onNavigate: (route, {dynamic args}) {
            if (route == 'pickup') {
              context.push('/bookings/$id/pickup');
            } else if (route == 'return') {
              context.push('/bookings/$id/return');
            } else if (route == 'payment') {
              context.push('/bookings/$id/payment');
            } else if (route == 'customer_profile') {
              context.push('/customers/$args');
            } else if (route == 'vehicle_edit') {
              context.push('/vehicles/$args/edit');
            }
          },
        );
      },
    ),
    GoRoute(
      path: '/bookings/:id/pickup',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'BK-1089';
        return PickupChecklistScreen(
          bookingId: id,
          onBack: () => context.pop(),
          onPickupConfirmed: () => context.pop(),
        );
      },
    ),
    GoRoute(
      path: '/bookings/:id/return',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'BK-1089';
        final bk = MockData.bookings.firstWhere(
          (b) => b.id == id,
          orElse: () => MockData.bookings.first,
        );
        return ReturnFinalBillScreen(
          booking: bk,
          onBillSettled: () {
            context.pushReplacement('/bookings/$id/payment');
          },
          onCancel: () => context.pop(),
        );
      },
    ),
    GoRoute(
      path: '/bookings/:id/payment',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'BK-1089';
        final bk = MockData.bookings.firstWhere(
          (b) => b.id == id,
          orElse: () => MockData.bookings.first,
        );
        return CollectPaymentScreen(
          booking: bk,
          onCollected: () => context.pop(),
          onCancel: () => context.pop(),
        );
      },
    ),

    // Vehicles Full Screen Routes
    GoRoute(
      path: AppRoutes.addVehicle,
      builder: (context, state) => AddVehicleScreen(
        onSaved: () => context.pop(),
        onCancel: () => context.pop(),
      ),
    ),
    GoRoute(
      path: '/vehicles/:id/edit',
      builder: (context, state) {
        return AddVehicleScreen(
          onSaved: () => context.pop(),
          onCancel: () => context.pop(),
        );
      },
    ),

    // Customers Full Screen Routes
    GoRoute(
      path: AppRoutes.customers,
      builder: (context, state) => CustomersListScreen(
        onNavigate: (route, {dynamic args}) {
          if (route == 'customer_profile' && args != null) {
            context.push('/customers/$args');
          } else if (route == 'add_customer') {
            context.push(AppRoutes.addCustomer);
          }
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.addCustomer,
      builder: (context, state) => const ComingSoonScreen(title: 'Add New Customer'),
    ),
    GoRoute(
      path: '/customers/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'CUST-01';
        final cust = MockData.customers.firstWhere(
          (c) => c.id == id,
          orElse: () => MockData.customers.first,
        );
        return CustomerProfileScreen(
          customer: cust,
          onBack: () => context.pop(),
        );
      },
    ),
    GoRoute(
      path: '/customers/:id/edit',
      builder: (context, state) => const ComingSoonScreen(title: 'Edit Customer Profile'),
    ),

    // Partners Full Screen Routes
    GoRoute(
      path: AppRoutes.partners,
      builder: (context, state) => PartnersListScreen(
        onNavigate: (route, {dynamic args}) {
          if (route == 'partner_ledger' && args != null) {
            context.push('/partners/$args/ledger');
          } else if (route == 'add_partner') {
            context.push(AppRoutes.addPartner);
          } else if (route == 'plans') {
            context.push(AppRoutes.plans);
          }
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.addPartner,
      builder: (context, state) => AddEditPartnerScreen(
        onSaved: () => context.pop(),
        onCancel: () => context.pop(),
      ),
    ),
    GoRoute(
      path: '/partners/:id/edit',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'PTR-01';
        final ptr = MockData.partners.firstWhere(
          (p) => p.id == id,
          orElse: () => MockData.partners.first,
        );
        return AddEditPartnerScreen(
          partner: ptr,
          onSaved: () => context.pop(),
          onCancel: () => context.pop(),
        );
      },
    ),
    GoRoute(
      path: '/partners/:id/ledger',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'PTR-01';
        final ptr = MockData.partners.firstWhere(
          (p) => p.id == id,
          orElse: () => MockData.partners.first,
        );
        return PartnerLedgerScreen(
          partner: ptr,
          onBack: () => context.pop(),
        );
      },
    ),

    // Reports Full Screen Routes
    GoRoute(
      path: AppRoutes.dailyMonthlyReport,
      builder: (context, state) => DailyMonthlyReportScreen(
        onBack: () => context.pop(),
      ),
    ),
    GoRoute(
      path: AppRoutes.vehicleWiseReport,
      builder: (context, state) => VehicleWiseReportScreen(
        onBack: () => context.pop(),
      ),
    ),
    GoRoute(
      path: AppRoutes.ledgerWiseReport,
      builder: (context, state) => const ComingSoonScreen(title: 'GST & Tax Accounting Export'),
    ),
    GoRoute(
      path: AppRoutes.maintenanceReport,
      builder: (context, state) => const ComingSoonScreen(title: 'Maintenance & Service Ledger'),
    ),
    GoRoute(
      path: AppRoutes.partnerPayoutReport,
      builder: (context, state) => const ComingSoonScreen(title: 'Partner Profit Payouts'),
    ),

    // Plans & Store Routes
    GoRoute(
      path: AppRoutes.plans,
      builder: (context, state) => PlansAndUsageScreen(
        onBack: () => context.pop(),
      ),
    ),
    GoRoute(
      path: AppRoutes.store,
      builder: (context, state) => StoreScreen(
        onNavigate: (route, {dynamic args}) {
          if (route == 'product_detail' && args != null) {
            context.push('/store/product/$args');
          }
        },
      ),
    ),
    GoRoute(
      path: '/store/product/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'PRD-01';
        final prod = MockData.storeProducts.firstWhere(
          (p) => p.id == id,
          orElse: () => MockData.storeProducts.first,
        );
        return ProductDetailEnquiryScreen(
          product: prod,
          onBack: () => context.pop(),
        );
      },
    ),

    // Settings Sub-Routes
    GoRoute(
      path: AppRoutes.usersAndRoles,
      builder: (context, state) => UsersAndRolesScreen(
        onBack: () => context.pop(),
      ),
    ),
    GoRoute(
      path: AppRoutes.whatsappTemplates,
      builder: (context, state) => WhatsappTemplatesWalletScreen(
        onBack: () => context.pop(),
      ),
    ),
    GoRoute(
      path: AppRoutes.whatsappLog,
      builder: (context, state) => const ComingSoonScreen(title: 'WhatsApp Message Dispatch Log'),
    ),
    GoRoute(
      path: AppRoutes.businessProfile,
      builder: (context, state) => const ComingSoonScreen(title: 'Business Profile'),
    ),
    GoRoute(
      path: AppRoutes.billingRules,
      builder: (context, state) => const ComingSoonScreen(title: 'GST & Billing Rules'),
    ),
    GoRoute(
      path: AppRoutes.invoiceFormat,
      builder: (context, state) => const ComingSoonScreen(title: 'Invoice Format'),
    ),
    GoRoute(
      path: AppRoutes.helpSupport,
      builder: (context, state) => const ComingSoonScreen(title: 'Help & Support'),
    ),
  ],
);
