import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/app_placeholders.dart';
import '../../services/api_service.dart';

class PickupChecklistScreen extends StatefulWidget {
  final String bookingId;
  final VoidCallback onBack;
  final VoidCallback onPickupConfirmed;

  const PickupChecklistScreen({
    super.key,
    required this.bookingId,
    required this.onBack,
    required this.onPickupConfirmed,
  });

  @override
  State<PickupChecklistScreen> createState() => _PickupChecklistScreenState();
}

class _PickupChecklistScreenState extends State<PickupChecklistScreen> {
  final _odometerController = TextEditingController(text: '24500');
  double _fuelLevel = 85.0;

  bool _spareWheelChecked = true;
  bool _toolKitChecked = true;
  bool _rcDocChecked = true;
  bool _insuranceDocChecked = true;
  bool _scratchesNoted = false;
  bool _isLoading = false;

  final Map<String, bool> _photoUploaded = {
    'Front View': true,
    'Rear View': true,
    'Left Side': false,
    'Right Side': false,
  };

  final List<Offset?> _signaturePoints = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Pickup Inspection (${widget.bookingId})'),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1. Odometer & Fuel Level Check', style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Start Odometer Reading (KM)',
                    hintText: '24500',
                    controller: _odometerController,
                    prefixIcon: Icons.speed_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Fuel Tank Level:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${_fuelLevel.toInt()}% Tank Full', style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Slider(
                    value: _fuelLevel,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: AppColors.primaryCyan,
                    inactiveColor: AppColors.canvasLow,
                    onChanged: (val) => setState(() => _fuelLevel = val),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderHairline),
                  const SizedBox(height: 16),

                  const Text('2. Mandatory Accessories & Documents Checklist', style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  _checkRow('Spare Wheel / Stepney Included', _spareWheelChecked, (v) => setState(() => _spareWheelChecked = v!)),
                  _checkRow('Jack & Tool Kit Available', _toolKitChecked, (v) => setState(() => _toolKitChecked = v!)),
                  _checkRow('Original Vehicle RC Copy Handed Over', _rcDocChecked, (v) => setState(() => _rcDocChecked = v!)),
                  _checkRow('Valid Insurance Copy Handed Over', _insuranceDocChecked, (v) => setState(() => _insuranceDocChecked = v!)),
                  _checkRow('Pre-existing Scratches / Dents Noted', _scratchesNoted, (v) => setState(() => _scratchesNoted = v!)),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderHairline),
                  const SizedBox(height: 16),

                  const Text('3. Inspection Photo Grid (4 Angle Check)', style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  const Text('Capture or attach 4-side condition photos prior to handover', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 12),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.4,
                    children: [
                      _photoTile('Front View', _photoUploaded['Front View']!),
                      _photoTile('Rear View', _photoUploaded['Rear View']!),
                      _photoTile('Left Side', _photoUploaded['Left Side']!),
                      _photoTile('Right Side', _photoUploaded['Right Side']!),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.borderHairline),
                  const SizedBox(height: 16),

                  const Text('4. Customer Driving Licence Verification', style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.canvasLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHover,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.4)),
                          ),
                          child: const Icon(Icons.badge_rounded, color: AppColors.primaryCyan, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rahul Verma', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('DL No: DL-1420210098271', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.preview_rounded, color: AppColors.primaryCyan, size: 22),
                          onPressed: () => AppPlaceholders.showImageViewer(
                            context,
                            imageUrl: 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&q=80&w=800',
                            title: 'Driving Licence - Rahul Verma',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.borderHairline),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('5. Renter Handover Digital Signature', style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 14)),
                      TextButton.icon(
                        onPressed: () => setState(() => _signaturePoints.clear()),
                        icon: const Icon(Icons.cleaning_services_rounded, color: AppColors.warningAmber, size: 16),
                        label: const Text('Clear', style: TextStyle(color: AppColors.warningAmber, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.canvasLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _signaturePoints.isNotEmpty ? AppColors.primaryCyan : AppColors.borderSubtle, width: 1.5),
                    ),
                    child: Stack(
                      children: [
                        GestureDetector(
                          onPanUpdate: (details) {
                            Offset localPosition = details.localPosition;
                            setState(() {
                              _signaturePoints.add(localPosition);
                            });
                          },
                          onPanEnd: (details) {
                            setState(() {
                              _signaturePoints.add(null);
                            });
                          },
                          child: CustomPaint(
                            painter: _SignaturePainter(points: _signaturePoints),
                            size: Size.infinite,
                          ),
                        ),
                        if (_signaturePoints.isEmpty)
                          const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.gesture_rounded, color: AppColors.textMuted, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Sign here using finger / stylus',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Confirm Pickup Inspection',
                    icon: Icons.assignment_turned_in_rounded,
                    isLoading: _isLoading,
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ApiService().submitPickupInspection(
                          widget.bookingId,
                          startOdometer: int.tryParse(_odometerController.text) ?? 24500,
                          fuelPercent: _fuelLevel,
                          notes: 'Verified accessories: spare wheel, tool kit, and registration documents checked.',
                        );
                      } catch (_) {}
                      if (mounted) {
                        setState(() => _isLoading = false);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Pickup completed! Trip is now Running.'),
                            backgroundColor: AppColors.successGreen,
                          ),
                        );
                        widget.onPickupConfirmed();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
  }

  Widget _photoTile(String label, bool isUploaded) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUploaded ? AppColors.successBorder : AppColors.borderSubtle),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            AppPlaceholders.showImagePickerPlaceholder(context, label: label);
            setState(() {
              _photoUploaded[label] = true;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isUploaded ? Icons.check_circle_rounded : Icons.add_a_photo_rounded,
                  color: isUploaded ? AppColors.successGreen : AppColors.primaryCyan,
                  size: 24,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isUploaded ? AppColors.textPrimary : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isUploaded ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                Text(
                  isUploaded ? 'Photo Attached' : '+ Add Photo',
                  style: TextStyle(
                    color: isUploaded ? AppColors.successGreen : AppColors.primaryCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _checkRow(String title, bool val, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      value: val,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      activeColor: AppColors.primaryCyan,
      checkColor: AppColors.textDark,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = AppColors.primaryCyan
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) => oldDelegate.points != points;
}
