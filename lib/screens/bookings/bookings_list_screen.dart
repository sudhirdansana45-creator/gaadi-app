import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/custom_button.dart';
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
  List<Booking> _bookings = [];

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
        if (mounted) {
          setState(() {
            _bookings = list;
          });
        }
      }
    } catch (_) {
      // Offline fallback: keep current list
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
      context.push('/bookings/new').then((_) => _loadBookings());
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Booked', 'Running', 'Returned', 'Cancelled', 'Late'];

    final filteredBookings = _bookings.where((b) {
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
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.primaryCyan.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.receipt_long_outlined, color: AppColors.primaryCyan, size: 40),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty || _selectedFilter != 'All'
                            ? 'No bookings matching filter'
                            : 'No Bookings Found in Ledger',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _searchQuery.isNotEmpty || _selectedFilter != 'All'
                            ? 'Try clearing the search query or changing status filters.'
                            : 'No bookings recorded yet. Generate your first booking bill to track running rentals and settlements.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      CustomButton(
                        text: '+ Create Booking',
                        width: 170,
                        height: 42,
                        onPressed: _onNewBookingTap,
                      ),
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
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.push('/bookings/${booking.id}').then((_) => _loadBookings()),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    booking.id,
                                    style: const TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  StatusChip.fromBookingStatus(booking.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                booking.customerName,
                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${booking.vehicleName} (${booking.vehicleRegNumber})',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.canvasLow,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
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
                              ),
                            ],
                          ),
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
      heroTag: null,
      backgroundColor: AppColors.primaryCyan,
      onPressed: _onNewBookingTap,
      icon: const Icon(Icons.add_rounded, color: AppColors.textDark),
      label: const Text('New Booking', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
    ),
  );
}
}
