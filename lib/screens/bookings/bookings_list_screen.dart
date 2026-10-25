import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/custom_button.dart';
import '../../data/mock_data.dart';
import '../../models/mock_models.dart';
import '../../core/plan_guard.dart';
import '../../services/api_service.dart';
import '../modals/daily_limit_modal.dart';

class BookingsListScreen extends StatefulWidget {
  final String? initialFilter;

  const BookingsListScreen({
    super.key,
    this.initialFilter,
  });

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  late String _selectedFilter;
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter ?? 'All';
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getBookings();
      if (res != null && res['data'] != null) {
        final list = (res['data'] as List)
            .map((item) => Booking.fromJson(item as Map<String, dynamic>))
            .toList();
        if (mounted && list.isNotEmpty) {
          setState(() {
            MockData.bookings = list;
          });
        }
      }
    } catch (_) {
      // Offline fallback
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onNewBookingTap() {
    if (!PlanGuard.canCreateBill()) {
      DailyLimitModal.show(
        context: context,
        onUpgrade: () {
          context.push('/plans');
        },
      );
    } else {
      context.push('/bookings/new');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Booked', 'Running', 'Returned', 'Cancelled', 'Late'];

    final filteredBookings = MockData.bookings.where((b) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = b.customerName.toLowerCase().contains(q) ||
            b.id.toLowerCase().contains(q) ||
            b.vehicleName.toLowerCase().contains(q) ||
            b.vehicleRegNumber.toLowerCase().contains(q);
        if (!matches) return false;
      }

      if (_selectedFilter == 'Booked') {
        return b.status == BookingStatus.pending;
      } else if (_selectedFilter == 'Running') {
        return b.status == BookingStatus.active;
      } else if (_selectedFilter == 'Returned') {
        return b.status == BookingStatus.completed;
      } else if (_selectedFilter == 'Cancelled') {
        return b.status == BookingStatus.cancelled;
      } else if (_selectedFilter == 'Late') {
        return b.status == BookingStatus.overdue;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadBookings,
          color: AppColors.primaryCyan,
          backgroundColor: AppColors.surfaceCard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.all(16),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bookings Ledger',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Active rentals, returns & payment settlements',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  CustomButton(
                    text: '+ New Booking',
                    width: 120,
                    height: 38,
                    onPressed: _onNewBookingTap,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by booking ID, customer or vehicle...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surfaceCard,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filters.map((filter) {
                    final isSel = _selectedFilter == filter;
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSel,
                        label: Text(filter),
                        labelStyle: TextStyle(
                          color: isSel ? AppColors.textDark : AppColors.textSecondary,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        selectedColor: AppColors.primaryCyan,
                        backgroundColor: AppColors.surfaceCard,
                        side: BorderSide(
                          color: isSel ? AppColors.primaryCyan : AppColors.borderSubtle,
                        ),
                        onSelected: (b) {
                          setState(() => _selectedFilter = filter);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Bookings List
              if (filteredBookings.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: const Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, color: AppColors.textMuted, size: 48),
                      SizedBox(height: 12),
                      Text('No bookings found matching filter.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, i) {
                    final booking = filteredBookings[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        onTap: () => context.push('/bookings/${booking.id}'),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              booking.id,
                              style: const TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            StatusChip.fromBookingStatus(booking.status),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text(
                              booking.customerName,
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${booking.vehicleName} (${booking.vehicleRegNumber})',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total: ₹${booking.totalAmount.toInt()}',
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                if (booking.pendingAmount > 0)
                                  Text(
                                    'Due: ₹${booking.pendingAmount.toInt()}',
                                    style: const TextStyle(color: AppColors.criticalRed, fontSize: 12, fontWeight: FontWeight.bold),
                                  )
                                else
                                  const Text(
                                    'Fully Paid',
                                    style: TextStyle(color: AppColors.successGreen, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryCyan,
        onPressed: _onNewBookingTap,
        icon: const Icon(Icons.add_rounded, color: AppColors.textDark),
        label: const Text('New Booking', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
