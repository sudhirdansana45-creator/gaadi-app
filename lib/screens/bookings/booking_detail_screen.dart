import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/custom_button.dart';
import '../../data/mock_data.dart';
import '../../data/dummy_plan_data.dart';
import '../../models/mock_models.dart';
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
  late Booking booking;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  void _loadBooking() {
    final found = MockData.bookings.firstWhere(
      (b) => b.id == widget.bookingId,
      orElse: () => Booking(
        id: widget.bookingId,
        customerName: 'Rahul Verma',
        customerPhone: '+91 98765 43210',
        vehicleName: 'Mahindra Thar 4x4',
        vehicleRegNumber: 'DL 01 AB 1234',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 2)),
        totalAmount: 10500.0,
        advancePaid: 3500.0,
        pendingAmount: 7000.0,
        securityDeposit: 5000.0,
        status: BookingStatus.active,
        startOdometer: 24200,
        paymentMode: 'UPI (GPay)',
        kycDocType: 'Aadhaar Card',
        kycDocNumber: '4829 **** 1092',
      ),
    );
    booking = found;
  }

  void _showExtendSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExtendBookingSheet(
        bookingId: booking.id,
        vehicleName: booking.vehicleName,
        currentTotal: booking.totalAmount,
        onExtendConfirmed: (additionalAmount, newEndDate) {
          setState(() {
            booking = Booking(
              id: booking.id,
              customerName: booking.customerName,
              customerPhone: booking.customerPhone,
              vehicleName: booking.vehicleName,
              vehicleRegNumber: booking.vehicleRegNumber,
              startDate: booking.startDate,
              endDate: newEndDate,
              totalAmount: booking.totalAmount + additionalAmount,
              advancePaid: booking.advancePaid,
              pendingAmount: booking.pendingAmount + additionalAmount,
              securityDeposit: booking.securityDeposit,
              status: booking.status,
              startOdometer: booking.startOdometer,
              paymentMode: booking.paymentMode,
              kycDocType: booking.kycDocType,
              kycDocNumber: booking.kycDocNumber,
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking extended! Additional ₹${additionalAmount.toInt()} added.'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        },
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => CancelBookingDialog(
        bookingId: booking.id,
        onCancelledConfirmed: () {
          setState(() {
            booking = Booking(
              id: booking.id,
              customerName: booking.customerName,
              customerPhone: booking.customerPhone,
              vehicleName: booking.vehicleName,
              vehicleRegNumber: booking.vehicleRegNumber,
              startDate: booking.startDate,
              endDate: booking.endDate,
              totalAmount: booking.totalAmount,
              advancePaid: booking.advancePaid,
              pendingAmount: 0.0,
              securityDeposit: booking.securityDeposit,
              status: BookingStatus.cancelled,
              startOdometer: booking.startOdometer,
              paymentMode: booking.paymentMode,
              kycDocType: booking.kycDocType,
              kycDocNumber: booking.kycDocNumber,
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking cancelled.'),
              backgroundColor: AppColors.criticalRed,
            ),
          );
          widget.onBack();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = DummyPlanData().currentRole == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Booking ${booking.id}'),
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
                      booking.id,
                      style: const TextStyle(color: AppColors.primaryCyan, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Created on ${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                StatusChip.fromBookingStatus(booking.status),
              ],
            ),
            const SizedBox(height: 16),

            // Vehicle Info Card (Clickable to vehicle edit)
            GestureDetector(
              onTap: () => widget.onNavigate('vehicle_edit', args: 'V001'),
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
                          Text(booking.vehicleName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(booking.vehicleRegNumber, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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

            // Customer Info Card (Clickable to customer profile)
            GestureDetector(
              onTap: () => widget.onNavigate('customer_profile', args: 'CUST-01'),
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
                              Text(booking.customerName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                              Text('${booking.customerPhone} • ${booking.kycDocType}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
                  _row('Total Trip Rental', '₹${booking.totalAmount.toInt()}'),
                  _row('Advance Paid', '₹${booking.advancePaid.toInt()}'),
                  _row('Security Deposit Held', '₹${booking.securityDeposit.toInt()}'),
                  const Divider(color: AppColors.borderHairline, height: 20),
                  _row('Pending Receivable', '₹${booking.pendingAmount.toInt()}', isBold: true, highlight: booking.pendingAmount > 0),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons Contextually Dependent on Status
            _buildStatusActions(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildStatusActions(BuildContext context) {
    final status = booking.status;

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
          if (booking.pendingAmount > 0) ...[
            CustomButton(
              text: 'Collect Balance Due (₹${booking.pendingAmount.toInt()})',
              icon: Icons.account_balance_wallet_rounded,
              onPressed: () => widget.onNavigate('payment'),
            ),
            const SizedBox(height: 10),
          ],
          CustomButton(
            text: 'Share Invoice & Receipt',
            variant: ButtonVariant.secondary,
            icon: Icons.share_rounded,
            onPressed: () => AppPlaceholders.showSharePlaceholder(context, title: 'Invoice ${booking.id}'),
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
