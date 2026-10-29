import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../data/mock_data.dart';
import '../../services/api_service.dart';
import '../../services/api_client.dart';
import '../../models/mock_models.dart';
import '../modals/daily_limit_modal.dart';

class HomeDashboardScreen extends StatefulWidget {
  final Function(String route, {dynamic args}) onNavigate;

  const HomeDashboardScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  Map<String, dynamic>? _dashboardStats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getDashboardStats();
      if (res != null && res['data'] != null) {
        final data = res['data'] as Map<String, dynamic>;
        if (data['user'] is Map<String, dynamic>) {
          await ApiClient().setUser(data['user'] as Map<String, dynamic>);
        }
        if (mounted) {
          setState(() {
            _dashboardStats = data;
          });
        }
        final recent = data['recent_bookings'] as List?;
        if (recent != null && recent.isNotEmpty) {
          for (final item in recent) {
            try {
              final b = Booking.fromJson(item as Map<String, dynamic>);
              final idx = MockData.bookings.indexWhere((existing) => existing.id == b.id);
              if (idx == -1) {
                MockData.bookings.insert(0, b);
              } else {
                MockData.bookings[idx] = b;
              }
            } catch (_) {}
          }
        }
      }
    } catch (_) {
      // Offline fallback: keep cached data
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleNewBookingTap(BuildContext context) {
    final quota = _dashboardStats?['quota'];
    final int billsToday = (quota?['bills_today'] as num?)?.toInt() ?? 0;
    final int billsPerDay = (quota?['bills_per_day'] as num?)?.toInt() ?? -1;
    final bool isLimitReached = (billsPerDay != -1 && billsToday >= billsPerDay);

    if (isLimitReached) {
      DailyLimitModal.show(
        context: context,
        onUpgrade: () => widget.onNavigate('plans_and_usage'),
      );
    } else {
      widget.onNavigate('new_booking');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: AppColors.primaryCyan,
        backgroundColor: const Color(0xFF1B1F2B),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(
                  color: AppColors.primaryCyan,
                  backgroundColor: AppColors.canvasLow,
                  minHeight: 2,
                ),
              ),
            // 0. Plan Expiry / Grace Banner (Dynamic from Backend Quota)
            _buildPlanStateBanner(context),

            // 1. Top Greeting & Business Snapshot Section
            _buildGreetingHeader(context),
            const SizedBox(height: 16),

            // 2. Plan Usage Counter Card ("Daily Invoice Quota")
            _buildInvoiceQuotaCard(context),
            const SizedBox(height: 20),

            // 3. Operational Quick Actions Row ("Express Desk")
            _buildExpressDeskRow(context),
            const SizedBox(height: 20),

            // 4. Metrics & Operations Grid ("Today's Pulse")
            _buildTodaysPulseGrid(context),
            const SizedBox(height: 20),

            // 5. Highlighted Offer Banner (Dynamic Store Promotions)
            _buildGpsOfferBanner(context),
            const SizedBox(height: 20),

            // 6. Recent Activity / Priority Returns List
            _buildPriorityReturnsSection(context),
            const SizedBox(height: 16),

            // 7. Garage Quick Stat Strip
            _buildGarageStatStrip(context),
            const SizedBox(height: 110), // Gap to prevent overlap with bottom tab menu
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildPlanStateBanner(BuildContext context) {
    final quota = _dashboardStats?['quota'];
    if (quota == null) return const SizedBox.shrink();

    final int? daysRemaining = (quota['days_remaining'] as num?)?.toInt();
    final String planName = quota['plan_name']?.toString() ?? 'Plan';

    if (daysRemaining != null && daysRemaining <= 0) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.criticalRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.criticalRed.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.criticalRed, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Your $planName has expired. Renew to continue adding bookings & vehicles.',
                style: const TextStyle(
                  color: AppColors.criticalRed,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CustomButton(
              text: 'Renew now',
              variant: ButtonVariant.destructive,
              height: 32,
              width: 95,
              onPressed: () => widget.onNavigate('plans_and_usage'),
            ),
          ],
        ),
      );
    } else if (daysRemaining != null && daysRemaining <= 3) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.warningBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warningBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warningAmber, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Your $planName expires in $daysRemaining day${daysRemaining > 1 ? "s" : ""}. Renew to avoid losing access.',
                style: const TextStyle(
                  color: AppColors.warningAmber,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CustomButton(
              text: 'Renew',
              variant: ButtonVariant.secondary,
              height: 32,
              width: 75,
              onPressed: () => widget.onNavigate('plans_and_usage'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ---------------------------------------------------------------------------
  // 1. GREETING & BUSINESS SNAPSHOT
  // ---------------------------------------------------------------------------
  Widget _buildGreetingHeader(BuildContext context) {
    final cachedUser = ApiClient().currentUser;
    final user = _dashboardStats?['user'] as Map<String, dynamic>? ?? cachedUser;
    final metrics = _dashboardStats?['metrics'];

    final String rawName = user?['name']?.toString().trim() ?? '';
    final String userName = rawName.isNotEmpty ? rawName : (_isLoading ? '...' : 'Operator');

    final String rawBusiness = user?['business_name']?.toString().trim() ?? '';
    final String businessName = rawBusiness.isNotEmpty ? rawBusiness : (_isLoading ? '...' : 'Fleet Operations');

    final int? totalFleet = (metrics?['total_vehicles'] as num?)?.toInt();
    final String fleetText = totalFleet != null
        ? '$totalFleet Active Fleet'
        : (_isLoading ? '...' : '0 Active Fleet');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Namaste, $userName',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('🙏', style: TextStyle(fontSize: 18)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4EDEAE),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF4EDEAE),
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      businessName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('•', style: TextStyle(color: Color(0xFF869397), fontSize: 12)),
                  const SizedBox(width: 6),
                  Text(
                    fleetText,
                    style: const TextStyle(
                      color: Color(0xFF4CD7F6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Gradient Button: + New Booking
        GestureDetector(
          onTap: () => _handleNewBookingTap(context),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFF0566D9)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(100),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x5906B6D4),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.add, color: Color(0xFF090E19), size: 20),
                SizedBox(width: 4),
                Text(
                  'New Booking',
                  style: TextStyle(
                    color: Color(0xFF090E19),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. DAILY INVOICE QUOTA CARD
  // ---------------------------------------------------------------------------
  Widget _buildInvoiceQuotaCard(BuildContext context) {
    final quota = _dashboardStats?['quota'];
    final bool hasQuota = quota != null;
    final int billsToday = (quota?['bills_today'] as num?)?.toInt() ?? 0;
    final int billsPerDay = (quota?['bills_per_day'] as num?)?.toInt() ?? -1;
    final int remaining = billsPerDay == -1 ? -1 : max(0, billsPerDay - billsToday);
    final double factor = billsPerDay <= 0
        ? (billsPerDay == -1 ? 0.05 : 0.0)
        : (billsToday / billsPerDay).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3854).withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Top accent gradient bar
          Container(
            height: 4,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [Color(0xFF4CD7F6), Color(0xFF06B6D4), Color(0xFF0566D9)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF252A36),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Color(0xFF4CD7F6),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DAILY INVOICE QUOTA',
                              style: TextStyle(
                                color: Color(0xFFBCC9CD),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: hasQuota ? '$billsToday' : (_isLoading ? '--' : '0'),
                                    style: const TextStyle(
                                      color: Color(0xFFDEE2F2),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text: hasQuota
                                        ? (billsPerDay == -1 ? '/∞ bills used today' : '/$billsPerDay bills used today')
                                        : (_isLoading ? '/-- bills used today' : '/10 bills used today'),
                                    style: const TextStyle(
                                      color: Color(0xFF869397),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => widget.onNavigate('plans_and_usage'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0566D9).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.bolt, color: Color(0xFF4CD7F6), size: 16),
                            SizedBox(width: 2),
                            Text(
                              'UPGRADE',
                              style: TextStyle(
                                color: Color(0xFF4CD7F6),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress Bar Container
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF090E19),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: factor,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF06B6D4), Color(0xFF4CD7F6)],
                        ),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF06B6D4),
                            blurRadius: 10,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      !hasQuota
                          ? (_isLoading ? 'Checking quota...' : 'Daily limit active')
                          : (billsPerDay == -1 ? 'Unlimited invoices' : '$remaining invoices remaining'),
                      style: const TextStyle(
                        color: Color(0xFF4CD7F6),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      'Resets at midnight',
                      style: TextStyle(
                        color: Color(0xFF869397),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. EXPRESS DESK (QUICK ACTIONS ROW)
  // ---------------------------------------------------------------------------
  Widget _buildExpressDeskRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Express Desk',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'FAST LANE',
              style: TextStyle(
                color: Color(0xFF869397),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildExpressButton(
                icon: Icons.key_rounded,
                iconColor: const Color(0xFF4CD7F6),
                label: 'Quick Out',
                onTap: () => _handleNewBookingTap(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildExpressButton(
                icon: Icons.checklist_rtl_rounded,
                iconColor: const Color(0xFF4EDEAE),
                label: 'Inspect In',
                onTap: () => widget.onNavigate('pickup_checklist'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildExpressButton(
                icon: Icons.send_rounded,
                iconColor: const Color(0xFFADC6FF),
                label: 'Pay Link',
                onTap: () => widget.onNavigate('collect_payment'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildExpressButton(
                icon: Icons.badge_rounded,
                iconColor: const Color(0xFF4CD7F6),
                label: 'Scan DL',
                onTap: () => widget.onNavigate('customers_list'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpressButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1F2B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A3854).withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFF252A36),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. TODAY'S PULSE (FINANCIALS & FLEET STATUS GRID)
  // ---------------------------------------------------------------------------
  Widget _buildTodaysPulseGrid(BuildContext context) {
    final metrics = _dashboardStats?['metrics'];
    final todayCash = (metrics?['today_revenue'] as num?)?.toInt() ?? 0;
    final pendingDue = (metrics?['pending_due'] as num?)?.toInt() ?? 0;
    final pendingInvoices = (metrics?['pending_invoices_count'] as num?)?.toInt() ?? 0;
    final onTripCount = (metrics?['rented_vehicles'] as num?)?.toInt() ?? 0;
    final returningCount = (metrics?['available_vehicles'] as num?)?.toInt() ?? 0;
    final overdueCount = (metrics?['overdue_bookings'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Pulse",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4EDEAE),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0xFF4EDEAE), blurRadius: 6, spreadRadius: 1),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Color(0xFF4CD7F6),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 2 Column Financials
        Row(
          children: [
            // Today's Cash Card
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onNavigate('daily_monthly_report'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1F2B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A3854).withValues(alpha: 0.4)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x73000000), blurRadius: 16, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "TODAY'S CASH",
                            style: TextStyle(
                              color: Color(0xFFBCC9CD),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4EDEAE).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.trending_up, color: Color(0xFF4EDEAE), size: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹$todayCash',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1BBD85).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              todayCash > 0 ? 'Active' : 'No bills yet',
                              style: const TextStyle(
                                color: Color(0xFF4EDEAE),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              'today total',
                              style: TextStyle(color: Color(0xFF869397), fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Pending Due Card
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onNavigate('collect_payment'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1F2B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A3854).withValues(alpha: 0.4)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x73000000), blurRadius: 16, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'PENDING DUE',
                            style: TextStyle(
                              color: Color(0xFFBCC9CD),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0566D9).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.pending_actions, color: Color(0xFFADC6FF), size: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹$pendingDue',
                        style: const TextStyle(
                          color: Color(0xFFADC6FF),
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0566D9).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(radius: 2, backgroundColor: Color(0xFFADC6FF)),
                                const SizedBox(width: 3),
                                Text(
                                  '$pendingInvoices invoices',
                                  style: const TextStyle(
                                    color: Color(0xFFE6ECFF),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              'to collect',
                              style: TextStyle(color: Color(0xFF869397), fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 3 Mini Cards Operations Fleet Status Row
        Row(
          children: [
            // On Trip
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1F2B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A3854).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ON TRIP',
                      style: TextStyle(color: Color(0xFFBCC9CD), fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$onTripCount',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Active on Road',
                      style: TextStyle(color: Color(0xFF869397), fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Returning
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1F2B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A3854).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AVAILABLE',
                          style: TextStyle(color: Color(0xFFBCC9CD), fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                        CircleAvatar(radius: 3, backgroundColor: Color(0xFF4CD7F6)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$returningCount Ready',
                      style: const TextStyle(color: Color(0xFF4CD7F6), fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'In Garage Depot',
                      style: TextStyle(color: Color(0xFF869397), fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Overdue / Late
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF93000A).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB4AB).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LATE',
                          style: TextStyle(color: Color(0xFFFFB4AB), fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB4AB), size: 14),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$overdueCount Alert',
                      style: const TextStyle(color: Color(0xFFFFB4AB), fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Action Req.',
                      style: TextStyle(color: Color(0xFFFFB4AB), fontSize: 10, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. HIGHLIGHTED OFFER BANNER (DYNAMIC STORE PROMOS)
  // ---------------------------------------------------------------------------
  Widget _buildGpsOfferBanner(BuildContext context) {
    final flashProducts = _dashboardStats?['flash_products'] as List?;
    final bool hasProduct = flashProducts != null && flashProducts.isNotEmpty;
    final Map<String, dynamic>? product = hasProduct ? (flashProducts.first as Map<String, dynamic>?) : null;

    final String title = product?['name']?.toString() ?? 'Fleet IoT Accessories & GPS Trackers';
    final String description = product?['description']?.toString() ??
        'Genuine IoT hardware, live tracking and vehicle sensors for your rental fleet.';
    final double? rawPrice = (product?['price'] as num?)?.toDouble();
    final double? rawDiscount = (product?['discount_price'] as num?)?.toDouble();
    final String productId = product?['id']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252A36),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3D494C)),
        boxShadow: const [
          BoxShadow(color: Color(0x80000000), blurRadius: 24, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1BBD85).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: Color(0xFF4EDEAE), size: 13),
                    const SizedBox(width: 4),
                    Text(
                      hasProduct && rawDiscount != null ? 'Flash Deal Available' : 'Verified Fleet Store',
                      style: const TextStyle(
                        color: Color(0xFF4EDEAE),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                hasProduct ? 'Available in Store' : 'Wholesale Rates',
                style: const TextStyle(color: Color(0xFF869397), fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF090E19),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.gps_fixed_rounded, color: Color(0xFF06B6D4), size: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFFBCC9CD),
                        fontSize: 11,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasProduct && (rawDiscount != null || rawPrice != null))
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '₹${(rawDiscount ?? rawPrice ?? 0).toInt()}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (rawDiscount != null && rawPrice != null && rawDiscount < rawPrice)
                            TextSpan(
                              text: ' ₹${rawPrice.toInt()}',
                              style: const TextStyle(
                                color: Color(0xFF869397),
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    const Text(
                      'Fleet Store Catalog',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const Text(
                    'Direct delivery to garage depot',
                    style: TextStyle(color: Color(0xFFBCC9CD), fontSize: 10),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  if (productId.isNotEmpty) {
                    widget.onNavigate('product_detail', args: productId);
                  } else {
                    widget.onNavigate('store');
                  }
                },
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0566D9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: Color(0x660566D9), blurRadius: 10, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        hasProduct ? 'View Device' : 'Explore Store',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. PRIORITY RETURNS (URGENT ALERTS & DUE SOON LIST)
  // ---------------------------------------------------------------------------
  Widget _buildPriorityReturnsSection(BuildContext context) {
    final recent = _dashboardStats?['recent_bookings'] as List?;
    final int overdueCount = (_dashboardStats?['metrics']?['overdue_bookings'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Priority Returns & Rentals',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (overdueCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF93000A).withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$overdueCount',
                        style: const TextStyle(
                          color: Color(0xFFFFB4AB),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            GestureDetector(
              onTap: () => widget.onNavigate('bookings'),
              child: const Text(
                'View All Schedule',
                style: TextStyle(
                  color: Color(0xFF4CD7F6),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (recent != null && recent.isNotEmpty)
          ...recent.take(3).map((item) {
            final b = item as Map<String, dynamic>;
            final bool isOverdue = b['is_overdue'] == true || b['status'] == 'overdue';
            final String vehicleName = b['vehicle_name']?.toString() ?? 'Vehicle';
            final String regNumber = b['vehicle_number']?.toString() ?? 'Fleet Vehicle';
            final String customerName = b['customer_name']?.toString() ?? 'Customer';
            final double amount = (b['amount'] as num?)?.toDouble() ?? 0.0;
            final String id = b['id']?.toString() ?? b['booking_id']?.toString() ?? '1';

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildPriorityReturnCard(
                context,
                imageUrl: 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&q=80&w=200',
                title: vehicleName,
                regPlate: regNumber,
                renterName: customerName,
                statusBadgeLabel: isOverdue ? 'Late / Overdue' : (b['status']?.toString().toUpperCase() ?? 'ACTIVE'),
                isOverdue: isOverdue,
                statusIcon: isOverdue ? Icons.timer_off_rounded : Icons.schedule_rounded,
                footerTextLeft: 'Fare: ₹${amount.toInt()}',
                footerTextRight: isOverdue ? 'Action Req.' : 'On Trip',
                onCheckIn: () => widget.onNavigate('booking_detail', args: id),
              ),
            );
          })
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1F2B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A3854).withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF4EDEAE), size: 36),
                const SizedBox(height: 8),
                const Text(
                  'No Overdue Returns',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'All fleet bookings are on track or vehicles are in depot.',
                  style: TextStyle(color: Color(0xFF869397), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: '+ Create New Booking',
                  height: 38,
                  width: 190,
                  onPressed: () => _handleNewBookingTap(context),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPriorityReturnCard(
    BuildContext context, {
    required String imageUrl,
    required String title,
    required String regPlate,
    required String renterName,
    required String statusBadgeLabel,
    required bool isOverdue,
    required IconData statusIcon,
    required String footerTextLeft,
    required String footerTextRight,
    required VoidCallback onCheckIn,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3854).withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(color: Color(0x59000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 44,
                        height: 44,
                        color: const Color(0xFF252A36),
                        child: const Icon(Icons.two_wheeler, color: Color(0xFF4CD7F6), size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF090E19),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              regPlate,
                              style: const TextStyle(
                                color: Color(0xFF4CD7F6),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('•', style: TextStyle(color: Color(0xFF869397), fontSize: 10)),
                          const SizedBox(width: 4),
                          Text(
                            renterName,
                            style: const TextStyle(color: Color(0xFFBCC9CD), fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? const Color(0xFF93000A).withValues(alpha: 0.3)
                      : const Color(0xFF0566D9).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    Icon(
                      statusIcon,
                      size: 13,
                      color: isOverdue ? const Color(0xFFFFB4AB) : const Color(0xFFADC6FF),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      statusBadgeLabel,
                      style: TextStyle(
                        color: isOverdue ? const Color(0xFFFFB4AB) : const Color(0xFFADC6FF),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Bottom Bar inside card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF171B27),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isOverdue ? Icons.local_gas_station : Icons.check_circle,
                      size: 14,
                      color: isOverdue ? const Color(0xFFFFB4AB) : const Color(0xFF4EDEAE),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      footerTextLeft,
                      style: const TextStyle(color: Color(0xFFBCC9CD), fontSize: 10),
                    ),
                    const SizedBox(width: 4),
                    const Text('•', style: TextStyle(color: Color(0xFF869397), fontSize: 10)),
                    const SizedBox(width: 4),
                    Text(
                      footerTextRight,
                      style: TextStyle(
                        color: isOverdue ? const Color(0xFFFFB4AB) : const Color(0xFF4EDEAE),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF4CD7F6), size: 14),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onCheckIn,
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252A36),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            isOverdue ? 'Check In' : 'Extend Trip',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. GARAGE QUICK STAT STRIP
  // ---------------------------------------------------------------------------
  Widget _buildGarageStatStrip(BuildContext context) {
    final cachedUser = ApiClient().currentUser;
    final user = _dashboardStats?['user'] as Map<String, dynamic>? ?? cachedUser;
    final String rawCity = user?['city']?.toString().trim() ?? '';
    final String depotLabel = rawCity.isNotEmpty ? 'Depot: $rawCity' : 'Depot: Operations Hub';
    final total = (_dashboardStats?['metrics']?['total_vehicles'] as num?)?.toInt() ?? 0;
    final avail = (_dashboardStats?['metrics']?['available_vehicles'] as num?)?.toInt() ?? 0;
    final int health = total > 0 ? ((avail / total) * 100).toInt() : (total == 0 ? 0 : 100);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171B27),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3854).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.store_rounded, color: Color(0xFF4EDEAE), size: 18),
              const SizedBox(width: 6),
              Text(
                depotLabel,
                style: const TextStyle(color: Color(0xFFBCC9CD), fontSize: 11),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                total > 0 ? 'Fleet Ready: $health%' : 'Fleet: 0 Vehicles',
                style: const TextStyle(
                  color: Color(0xFF4CD7F6),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.verified, color: Color(0xFF4CD7F6), size: 14),
            ],
          ),
        ],
      ),
    );
  }
}
