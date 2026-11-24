import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
        final match = list.where((b) {
          if (b.id == widget.bookingId) return true;
          if (b.displayId.toLowerCase() == widget.bookingId.toLowerCase()) return true;
          final cleanWidget = widget.bookingId.replaceAll(RegExp(r'[^0-9]'), '');
          final cleanB = b.id.replaceAll(RegExp(r'[^0-9]'), '');
          return cleanWidget.isNotEmpty && cleanWidget == cleanB;
        }).firstOrNull;
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
        title: Text('Booking ${currentBooking.displayId}'),
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
                        currentBooking.displayId,
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

              // 1. Start Pickup & Handover Details Card (with photos)
              _buildPickupInspectionCard(context, currentBooking),
              const SizedBox(height: 16),

              // 2. End Trip & Return Settlement Card
              _buildReturnInspectionCard(context, currentBooking),
              const SizedBox(height: 16),

              // Payment Ledger Summary
              Builder(
                builder: (context) {
                  final diffHours = currentBooking.endDate.difference(currentBooking.startDate).inHours;
                  final tripDurationDays = diffHours > 0 ? (diffHours / 24).ceil().clamp(1, 365) : 1;
                  final displayRental = currentBooking.totalAmount > 0
                      ? currentBooking.totalAmount
                      : (currentBooking.vehicleName.toLowerCase().contains('bike') ? 800.0 : 2200.0) * tripDurationDays;
                  final displayDeposit = currentBooking.securityDeposit > 0
                      ? currentBooking.securityDeposit
                      : (currentBooking.vehicleName.toLowerCase().contains('bike') ? 1500.0 : 3000.0);
                  final displayAdvance = currentBooking.advancePaid;
                  final displayPending = (displayRental - displayAdvance).clamp(0.0, 9999999.0);

                  final isFullyPaid = displayPending <= 0;
                  final isPartial = displayAdvance > 0 && displayPending > 0;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.receipt_long_rounded, color: AppColors.primaryCyan, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Payment Ledger Breakdown',
                                  style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isFullyPaid
                                    ? AppColors.successBg
                                    : (isPartial ? AppColors.warningBg : AppColors.criticalBg),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isFullyPaid ? 'Fully Paid' : (isPartial ? 'Partially Paid' : 'Payment Pending'),
                                style: TextStyle(
                                  color: isFullyPaid
                                      ? AppColors.successGreen
                                      : (isPartial ? AppColors.warningAmber : AppColors.criticalRed),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _row(
                          'Total Trip Rental ($tripDurationDays ${tripDurationDays == 1 ? "day" : "days"})',
                          '₹${displayRental.toInt()}',
                        ),
                        _row('Advance Paid', '₹${displayAdvance.toInt()}'),
                        _row('Security Deposit Held', '₹${displayDeposit.toInt()}'),
                        const Divider(color: AppColors.borderHairline, height: 20),
                        _row(
                          'Pending Receivable',
                          '₹${displayPending.toInt()}',
                          isBold: true,
                          highlight: displayPending > 0,
                        ),
                      ],
                    ),
                  );
                },
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

  // ---------------------------------------------------------------------------
  // INSPECTION & LIFECYCLE WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildPickupInspectionCard(BuildContext context, Booking currentBooking) {
    final hasPickup = currentBooking.hasPickupInspection || currentBooking.status != BookingStatus.pending;
    final photosMap = currentBooking.pickupPhotos;
    final allPhotos = currentBooking.allPickupPhotos;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.key_rounded, color: AppColors.primaryCyan, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Pickup Inspection & Handover',
                    style: TextStyle(
                      color: AppColors.primaryCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasPickup ? AppColors.successBg : AppColors.canvasLow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasPickup ? 'Completed' : 'Pending',
                  style: TextStyle(
                    color: hasPickup ? AppColors.successGreen : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (!hasPickup) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.canvasLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.primaryCyan, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Vehicle pickup checklist has not been submitted yet. Once customer arrives, tap "Start Pickup Checklist" below to record start odometer and vehicle photos.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Key stats: Start Odometer, Fuel Level %, Handover Time
            Row(
              children: [
                Expanded(
                  child: _statTile(
                    icon: Icons.speed_rounded,
                    label: 'Start Odometer',
                    value: '${currentBooking.startOdometer} KM',
                    accentColor: AppColors.primaryCyan,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statTile(
                    icon: Icons.local_gas_station_rounded,
                    label: 'Fuel Level',
                    value: '${currentBooking.fuelLevelPercent?.toInt() ?? 100}% Full',
                    accentColor: AppColors.successGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (currentBooking.pickupAt != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: AppColors.textMuted, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Handed Over: ${dateFormat.format(currentBooking.pickupAt!)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),

            // Accessories Checklist Badges
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.canvasLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _CheckBadge(label: 'Spare Tyre Checked'),
                  _CheckBadge(label: 'Tool Kit Verified'),
                  _CheckBadge(label: 'RC Copy Handed'),
                  _CheckBadge(label: 'Insurance Valid'),
                ],
              ),
            ),

            if (currentBooking.pickupNotes != null && currentBooking.pickupNotes!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.canvasLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes_rounded, color: AppColors.textSecondary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentBooking.pickupNotes!,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Photos Section
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.photo_library_rounded, color: AppColors.primaryCyan, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Inspection Photos (${allPhotos.length})',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (allPhotos.isNotEmpty)
                  const Text(
                    'Tap photo to zoom',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (allPhotos.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.canvasLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.no_photography_outlined, color: AppColors.textMuted, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'No inspection photos recorded for this pickup.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              _buildPhotosGallery(context, photosMap, allPhotos),
          ],
        ],
      ),
    );
  }

  Widget _buildReturnInspectionCard(BuildContext context, Booking currentBooking) {
    final status = currentBooking.status;
    final isRunning = status == BookingStatus.active || status == BookingStatus.overdue;
    final isClosed = status == BookingStatus.completed || currentBooking.hasReturnInspection;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    if (!isRunning && !isClosed) {
      return const SizedBox.shrink();
    }

    final totalKms = currentBooking.totalKmsDriven;
    final extraKmCharge = currentBooking.extraKmCharge ?? 0.0;
    final fuelCharge = currentBooking.fuelCharge ?? 0.0;
    final damageDeduction = currentBooking.damageDeduction ?? 0.0;
    final finalSettlement = currentBooking.finalSettlementAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.assignment_turned_in_rounded, color: AppColors.primaryCyan, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Trip End & Return Settlement',
                    style: TextStyle(
                      color: AppColors.primaryCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isClosed ? AppColors.successBg : AppColors.warningBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isClosed ? 'Returned & Settled' : 'Trip in Progress',
                  style: TextStyle(
                    color: isClosed ? AppColors.successGreen : AppColors.warningAmber,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (isRunning) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.canvasLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_car_filled_rounded, color: AppColors.warningAmber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Trip is running since ${currentBooking.pickupAt != null ? dateFormat.format(currentBooking.pickupAt!) : "pickup"}. Return odometer, extra KMs, fuel and damage inspection will be recorded when vehicle is returned.',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // End odometer stats
            Row(
              children: [
                Expanded(
                  child: _statTile(
                    icon: Icons.speed_rounded,
                    label: 'End Odometer',
                    value: currentBooking.endOdometer != null ? '${currentBooking.endOdometer} KM' : 'Recorded',
                    accentColor: AppColors.primaryCyan,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statTile(
                    icon: Icons.route_rounded,
                    label: 'Total Driven',
                    value: totalKms != null ? '$totalKms KM' : 'N/A',
                    accentColor: AppColors.warningAmber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (currentBooking.settledAt != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: AppColors.successGreen, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Returned On: ${dateFormat.format(currentBooking.settledAt!)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),

            // Itemized Return Settlement Charges
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.canvasLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _row('Extra KM Charges', '₹${extraKmCharge.toInt()}'),
                  _row('Fuel Shortage Charge', '₹${fuelCharge.toInt()}'),
                  _row('Damage Deductions', '₹${damageDeduction.toInt()}', highlight: damageDeduction > 0),
                  const Divider(color: AppColors.borderHairline, height: 14),
                  _row(
                    'Final Settlement Amount',
                    '₹${finalSettlement != null ? finalSettlement.toInt() : (extraKmCharge + fuelCharge + damageDeduction).toInt()}',
                    isBold: true,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotosGallery(BuildContext context, Map<String, List<String>> photosMap, List<String> allPhotos) {
    // If categorized by angle
    if (photosMap.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: photosMap.entries.map((entry) {
          final angle = entry.key;
          final photos = entry.value;
          if (photos.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryCyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$angle (${photos.length})',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(width: 10),
                    itemBuilder: (ctx, i) => _buildPhotoThumbnail(context, photos[i], '$angle #${i + 1}'),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    // Flat list fallback
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: allPhotos.length,
        separatorBuilder: (ctx, idx) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) => _buildPhotoThumbnail(context, allPhotos[i], 'Photo #${i + 1}'),
      ),
    );
  }

  Widget _buildPhotoThumbnail(BuildContext context, String url, String angle) {
    return GestureDetector(
      onTap: () => _showPhotoPreview(context, url, angle),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.surfaceHover,
            border: Border.all(color: AppColors.borderSubtle),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _renderImageWidget(url),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  color: Colors.black.withValues(alpha: 0.65),
                  child: Text(
                    angle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _renderImageWidget(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryCyan),
            ),
          );
        },
        errorBuilder: (ctx, err, stack) => const Center(
          child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 24),
        ),
      );
    }

    try {
      String clean = url;
      if (clean.contains('base64,')) {
        clean = clean.split('base64,').last;
      }
      final bytes = base64Decode(clean);
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (_) {
      return const Center(
        child: Icon(Icons.directions_car_rounded, color: AppColors.primaryCyan, size: 24),
      );
    }
  }

  void _showPhotoPreview(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.75,
                    maxWidth: MediaQuery.of(context).size.width * 0.95,
                  ),
                  color: AppColors.surfaceCard,
                  child: InteractiveViewer(
                    maxScale: 4.0,
                    child: _renderImageWidget(imageUrl),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statTile({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.canvasLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckBadge extends StatelessWidget {
  final String label;

  const _CheckBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
