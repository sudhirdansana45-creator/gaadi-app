import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/custom_button.dart';
import '../../models/mock_models.dart';
import '../../services/api_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_placeholders.dart';
import 'extend_booking_sheet.dart';
import 'cancel_booking_dialog.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  final Function(String route, {dynamic args}) onNavigate;
  final VoidCallback onBack;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
    required this.onNavigate,
    required this.onBack,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Booking? booking;
  bool _isLoading = true;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() {
      _isLoading = true;
      _notFound = false;
    });

    try {
      final res = await ApiService().getBookingDetail(widget.bookingId);
      if (res != null && res['data'] != null) {
        if (mounted) {
          setState(() {
            booking = Booking.fromJson(res['data'] as Map<String, dynamic>);
            _isLoading = false;
          });
        }
        return;
      }

      // Fallback check from list in case lookup by order_no matches
      final allRes = await ApiService().getBookings();
      if (allRes != null && allRes['data'] is List) {
        final list = (allRes['data'] as List)
            .map((item) => Booking.fromJson(item as Map<String, dynamic>))
            .toList();
        final match = list.where((b) => b.id == widget.bookingId).firstOrNull;
        if (match != null && mounted) {
          setState(() {
            booking = match;
            _isLoading = false;
          });
          return;
        }
      }

      if (mounted) {
        setState(() {
          _notFound = true;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _notFound = true;
          _isLoading = false;
        });
      }
    }
  }

  void _showExtendSheet() {
    if (booking == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExtendBookingSheet(
        bookingId: booking!.id,
        vehicleName: booking!.vehicleName,
        currentTotal: booking!.totalAmount,
        onExtendConfirmed: (additionalAmount, newEndDate) {
          _loadBooking();
        },
      ),
    );
  }

  void _showCancelDialog() {
    if (booking == null) return;
    showDialog(
      context: context,
      builder: (ctx) => CancelBookingDialog(
        bookingId: booking!.id,
        onCancelledConfirmed: () {
          widget.onBack();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Booking ${widget.bookingId}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: widget.onBack,
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryCyan),
        ),
      );
    }

    if (_notFound || booking == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Booking Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: widget.onBack,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.criticalRed.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.search_off_rounded, color: AppColors.criticalRed, size: 48),
                ),
                const SizedBox(height: 20),
                Text(
                  'Booking #${widget.bookingId} Not Found',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This booking record does not exist on your account or may have been deleted.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Back to Bookings',
                  width: 180,
                  onPressed: widget.onBack,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentBooking = booking!;
    final userRole = ApiClient().currentUser?['role']?.toString().toLowerCase();
    final isAdmin = userRole == 'admin' || userRole == 'owner';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Booking ${currentBooking.id}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onBack,
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentBooking.id,
                        style: const TextStyle(color: AppColors.primaryCyan, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Created on ${currentBooking.startDate.day}/${currentBooking.startDate.month}/${currentBooking.startDate.year}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  StatusChip.fromBookingStatus(currentBooking.status),
                ],
              ),
              const SizedBox(height: 16),

              // Vehicle Info Card
              GestureDetector(
                onTap: () {
                  if (currentBooking.vehicleId != null && currentBooking.vehicleId!.isNotEmpty) {
                    widget.onNavigate('vehicle_edit', args: currentBooking.vehicleId);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.directions_car_rounded, color: AppColors.primaryCyan, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentBooking.vehicleName,
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              currentBooking.vehicleRegNumber,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            if (isAdmin) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warningBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Partner Share: 70%',
                                  style: TextStyle(color: AppColors.warningAmber, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Customer Info Card
              GestureDetector(
                onTap: () {
                  if (currentBooking.customerId != null && currentBooking.customerId!.isNotEmpty) {
                    widget.onNavigate('customer_profile', args: currentBooking.customerId);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Customer & KYC Details', style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 13)),
                          Icon(Icons.verified_user_rounded, color: AppColors.successGreen, size: 18),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.surfaceHover,
                            child: Icon(Icons.person_rounded, color: AppColors.primaryCyan, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentBooking.customerName,
                                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  '${currentBooking.customerPhone} • ${currentBooking.kycDocType}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Payment Ledger Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Ledger Breakdown', style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 12),
                    _row('Total Trip Rental', '₹${currentBooking.totalAmount.toInt()}'),
                    _row('Advance Paid', '₹${currentBooking.advancePaid.toInt()}'),
                    _row('Security Deposit Held', '₹${currentBooking.securityDeposit.toInt()}'),
                    const Divider(color: AppColors.borderHairline, height: 20),
                    _row('Pending Receivable', '₹${currentBooking.pendingAmount.toInt()}', isBold: true, highlight: currentBooking.pendingAmount > 0),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons Contextually Dependent on Status
              _buildStatusActions(context, currentBooking),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusActions(BuildContext context, Booking currentBooking) {
    final status = currentBooking.status;

    if (status == BookingStatus.pending) {
      // Pending / Booked status
      return Column(
        children: [
          CustomButton(
            text: 'Start Pickup Checklist',
            icon: Icons.checklist_rounded,
            onPressed: () => widget.onNavigate('pickup'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Extend Trip',
                  variant: ButtonVariant.secondary,
                  icon: Icons.calendar_today_rounded,
                  onPressed: _showExtendSheet,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomButton(
                  text: 'Cancel Booking',
                  variant: ButtonVariant.destructive,
                  icon: Icons.cancel_outlined,
                  onPressed: _showCancelDialog,
                ),
              ),
            ],
          ),
        ],
      );
    } else if (status == BookingStatus.active || status == BookingStatus.overdue) {
      // Active / Running / Overdue status
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Return & Final Bill',
                  icon: Icons.assignment_turned_in_rounded,
                  onPressed: () => widget.onNavigate('return'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomButton(
                  text: 'Collect Payment',
                  variant: ButtonVariant.secondary,
                  icon: Icons.account_balance_wallet_rounded,
                  onPressed: () => widget.onNavigate('payment'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: 'Extend Duration',
            variant: ButtonVariant.ghost,
            icon: Icons.more_time_rounded,
            onPressed: _showExtendSheet,
          ),
        ],
      );
    } else if (status == BookingStatus.completed) {
      // Returned / Completed status
      return Column(
        children: [
          if (currentBooking.pendingAmount > 0) ...[
            CustomButton(
              text: 'Collect Balance Due (₹${currentBooking.pendingAmount.toInt()})',
              icon: Icons.account_balance_wallet_rounded,
              onPressed: () => widget.onNavigate('payment'),
            ),
            const SizedBox(height: 10),
          ],
          CustomButton(
            text: 'Share Invoice & Receipt',
            variant: ButtonVariant.secondary,
            icon: Icons.share_rounded,
            onPressed: () => AppPlaceholders.showSharePlaceholder(context, title: 'Invoice ${currentBooking.id}'),
          ),
        ],
      );
    } else {
      // Cancelled status
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.criticalBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.criticalBorder),
        ),
        child: const Center(
          child: Text(
            'This booking has been cancelled.',
            style: TextStyle(color: AppColors.criticalRed, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      );
    }
  }

  Widget _row(String title, String val, {bool isBold = false, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: isBold ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
          Text(val, style: TextStyle(color: highlight ? AppColors.warningAmber : (isBold ? AppColors.primaryCyan : AppColors.textPrimary), fontSize: isBold ? 16 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }
}
