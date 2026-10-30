import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/mock_models.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final bool showDot;

  const StatusChip({
    super.key,
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    this.showDot = true,
  });

  // Variant: Available (Green)
  factory StatusChip.available({String label = 'Available'}) {
    return StatusChip(
      label: label,
      textColor: AppColors.successGreen,
      backgroundColor: AppColors.successBg,
      borderColor: AppColors.successBorder,
    );
  }

  // Variant: Booked (Blue)
  factory StatusChip.booked({String label = 'Booked'}) {
    return StatusChip(
      label: label,
      textColor: AppColors.infoBlue,
      backgroundColor: AppColors.infoBg,
      borderColor: AppColors.infoBorder,
    );
  }

  // Variant: Running (Cyan / Emerald)
  factory StatusChip.running({String label = 'Running / Active'}) {
    return StatusChip(
      label: label,
      textColor: AppColors.primaryCyan,
      backgroundColor: AppColors.successBg,
      borderColor: AppColors.successBorder,
    );
  }

  // Variant: In Service (Amber)
  factory StatusChip.inService({String label = 'In Service'}) {
    return StatusChip(
      label: label,
      textColor: AppColors.warningAmber,
      backgroundColor: AppColors.warningBg,
      borderColor: AppColors.warningBorder,
    );
  }

  // Variant: Disabled (Grey)
  factory StatusChip.disabled({String label = 'Disabled'}) {
    return StatusChip(
      label: label,
      textColor: AppColors.textMuted,
      backgroundColor: AppColors.canvasLow,
      borderColor: AppColors.borderSubtle,
      showDot: false,
    );
  }

  // Variant: Overdue / Late (Red)
  factory StatusChip.overdue({String label = 'Overdue / Late'}) {
    return StatusChip(
      label: label,
      textColor: AppColors.criticalRed,
      backgroundColor: AppColors.criticalBg,
      borderColor: AppColors.criticalBorder,
    );
  }

  // Variant: Verified (Green)
  factory StatusChip.verified({String label = 'Verified'}) {
    return StatusChip(
      label: label,
      textColor: AppColors.successGreen,
      backgroundColor: AppColors.successBg,
      borderColor: AppColors.successBorder,
    );
  }

  // Variant: Blacklisted (Red)
  factory StatusChip.blacklisted({String label = 'Blacklisted'}) {
    return StatusChip(
      label: label,
      textColor: AppColors.criticalRed,
      backgroundColor: AppColors.criticalBg,
      borderColor: AppColors.criticalBorder,
    );
  }

  factory StatusChip.fromVehicleStatus(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.available:
        return StatusChip.available();
      case VehicleStatus.booked:
        return StatusChip.booked();
      case VehicleStatus.inService:
        return StatusChip.inService();
      case VehicleStatus.disabled:
        return StatusChip.disabled();
      case VehicleStatus.reserved:
        return StatusChip.running(label: 'Reserved');
    }
  }

  factory StatusChip.fromBookingStatus(BookingStatus status) {
    switch (status) {
      case BookingStatus.active:
        return StatusChip.running(label: 'Active Trip');
      case BookingStatus.pending:
        return StatusChip.inService(label: 'Pending');
      case BookingStatus.completed:
        return StatusChip.booked(label: 'Completed');
      case BookingStatus.overdue:
        return StatusChip.overdue(label: 'Overdue Return');
      case BookingStatus.cancelled:
        return StatusChip.disabled(label: 'Cancelled');
    }
  }

  factory StatusChip.fromPartnerStatus(PartnerStatus status) {
    switch (status) {
      case PartnerStatus.active:
        return StatusChip.available(label: 'Active');
      case PartnerStatus.inactive:
        return StatusChip.disabled(label: 'Inactive');
      case PartnerStatus.viewOnly:
        return StatusChip.disabled(label: 'View Only');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
