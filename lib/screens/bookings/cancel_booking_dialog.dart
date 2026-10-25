import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../services/api_service.dart';

class CancelBookingDialog extends StatelessWidget {
  final String bookingId;
  final VoidCallback onCancelledConfirmed;

  const CancelBookingDialog({
    super.key,
    required this.bookingId,
    required this.onCancelledConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      title: Row(
        children: const [
          Icon(Icons.cancel_outlined, color: AppColors.criticalRed, size: 24),
          SizedBox(width: 10),
          Text('Cancel Booking', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: Text(
        'Are you sure you want to cancel booking $bookingId? This will mark the booking as cancelled and free up the vehicle.',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
      ),
      actionsPadding: const EdgeInsets.all(16),
      actions: [
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Keep Trip',
                variant: ButtonVariant.ghost,
                height: 40,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomButton(
                text: 'Confirm Cancel',
                variant: ButtonVariant.destructive,
                height: 40,
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await ApiService().cancelBooking(
                      bookingId,
                      reason: 'Cancelled by operator via booking desk.',
                    );
                  } catch (_) {}
                  onCancelledConfirmed();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
