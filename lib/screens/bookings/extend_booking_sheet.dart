import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../services/api_service.dart';

class ExtendBookingSheet extends StatefulWidget {
  final String bookingId;
  final String vehicleName;
  final double currentTotal;
  final Function(double additionalAmount, DateTime newEndDate) onExtendConfirmed;

  const ExtendBookingSheet({
    super.key,
    required this.bookingId,
    required this.vehicleName,
    required this.currentTotal,
    required this.onExtendConfirmed,
  });

  @override
  State<ExtendBookingSheet> createState() => _ExtendBookingSheetState();
}

class _ExtendBookingSheetState extends State<ExtendBookingSheet> {
  int _extraDays = 1;
  late double _additionalAmount;

  @override
  void initState() {
    super.initState();
    _additionalAmount = 2500.0 * _extraDays;
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: 'Extend Trip Duration',
      subtitle: 'Booking ${widget.bookingId} • ${widget.vehicleName}',
      primaryActionText: 'Confirm Extension (₹${_additionalAmount.toInt()})',
      onPrimaryAction: () async {
        Navigator.pop(context);
        final newEndDate = DateTime.now().add(Duration(days: _extraDays + 1));
        try {
          await ApiService().extendBooking(
            widget.bookingId,
            newEndDate: newEndDate.toIso8601String(),
            extraAmount: _additionalAmount,
          );
        } catch (_) {}
        widget.onExtendConfirmed(_additionalAmount, newEndDate);
      },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Add Extra Duration', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.primaryCyan),
                    onPressed: _extraDays > 1 ? () => setState(() { _extraDays--; _additionalAmount = 2500.0 * _extraDays; }) : null,
                  ),
                  Text('$_extraDays Days', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryCyan),
                    onPressed: () => setState(() { _extraDays++; _additionalAmount = 2500.0 * _extraDays; }),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Additional Rent:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text('₹${_additionalAmount.toInt()}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('New Trip Total:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text('₹${(widget.currentTotal + _additionalAmount).toInt()}', style: const TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
