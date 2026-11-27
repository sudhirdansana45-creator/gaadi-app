import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/media/media_picker_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/app_placeholders.dart';
import '../../models/mock_models.dart';
import '../../services/api_service.dart';

class InspectionPhoto {
  final Uint8List? bytes;
  final String? base64;
  final String? url;
  final String name;

  InspectionPhoto({
    this.bytes,
    this.base64,
    this.url,
    required this.name,
  });

  bool get isMemory => bytes != null;
  bool get isNetwork => url != null && url!.isNotEmpty;
}

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
  final _odometerController = TextEditingController();
  double _fuelLevel = 100.0;
  Booking? _booking;

  bool _spareWheelChecked = true;
  bool _toolKitChecked = true;
  bool _rcDocChecked = true;
  bool _insuranceDocChecked = true;
  bool _scratchesNoted = false;
  bool _isLoading = false;

  final Map<String, List<InspectionPhoto>> _photosByAngle = {
    'Front View': [],
    'Rear View': [],
    'Left Side': [],
    'Right Side': [],
  };

  final Map<String, IconData> _angleIcons = {
    'Front View': Icons.directions_car_rounded,
    'Rear View': Icons.rv_hookup_rounded,
    'Left Side': Icons.turn_left_rounded,
    'Right Side': Icons.turn_right_rounded,
  };

  final Map<String, List<InspectionPhoto>> _kycDocuments = {
    'Driving Licence': [],
    'Aadhaar Card': [],
    'Additional Document': [],
  };

  final Map<String, IconData> _kycDocIcons = {
    'Driving Licence': Icons.badge_rounded,
    'Aadhaar Card': Icons.fingerprint_rounded,
    'Additional Document': Icons.file_present_rounded,
  };

  int get _totalKycDocsCount {
    int count = 0;
    for (final list in _kycDocuments.values) {
      count += list.length;
    }
    return count;
  }

  final List<Offset?> _signaturePoints = [];

  @override
  void initState() {
    super.initState();
    _loadBookingOdometer();
  }

  Future<void> _loadBookingOdometer() async {
    try {
      final res = await ApiService().getBookingDetail(widget.bookingId);
      if (res != null && res['data'] != null && mounted) {
        final b = Booking.fromJson(res['data'] as Map<String, dynamic>);
        setState(() {
          _booking = b;
          if (b.startOdometer > 0) {
            _odometerController.text = b.startOdometer.toString();
          }

          // Preload customer KYC documents from backend if present
          if (b.customerDocuments != null && b.customerDocuments!.isNotEmpty) {
            final docs = b.customerDocuments!;
            if (docs['dl_front'] != null && docs['dl_front']!.isNotEmpty) {
              if (!(_kycDocuments['Driving Licence']?.any((p) => p.url == docs['dl_front']) ?? false)) {
                _kycDocuments['Driving Licence']?.add(InspectionPhoto(name: 'DL Front', url: docs['dl_front']));
              }
            }
            if (docs['dl_back'] != null && docs['dl_back']!.isNotEmpty) {
              if (!(_kycDocuments['Driving Licence']?.any((p) => p.url == docs['dl_back']) ?? false)) {
                _kycDocuments['Driving Licence']?.add(InspectionPhoto(name: 'DL Back', url: docs['dl_back']));
              }
            }
            if (docs['aadhar_front'] != null && docs['aadhar_front']!.isNotEmpty) {
              if (!(_kycDocuments['Aadhaar Card']?.any((p) => p.url == docs['aadhar_front']) ?? false)) {
                _kycDocuments['Aadhaar Card']?.add(InspectionPhoto(name: 'Aadhaar Front', url: docs['aadhar_front']));
              }
            }
            if (docs['aadhar_back'] != null && docs['aadhar_back']!.isNotEmpty) {
              if (!(_kycDocuments['Aadhaar Card']?.any((p) => p.url == docs['aadhar_back']) ?? false)) {
                _kycDocuments['Aadhaar Card']?.add(InspectionPhoto(name: 'Aadhaar Back', url: docs['aadhar_back']));
              }
            }
          }

          // Also check if pickup inspection already has saved KYC photos
          if (b.pickupPhotos.isNotEmpty) {
            b.pickupPhotos.forEach((k, list) {
              if (_kycDocuments.containsKey(k)) {
                for (final url in list) {
                  if (url.isNotEmpty && !(_kycDocuments[k]?.any((p) => p.url == url) ?? false)) {
                    _kycDocuments[k]?.add(InspectionPhoto(name: '$k Photo', url: url));
                  }
                }
              }
            });
          }
        });
      }
    } catch (_) {}
  }

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
                    hintText: 'e.g. 12500',
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

                  const Text('3. Inspection Photos (4 Angle Check - Multiple Photos)', style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  const Text('Capture or upload multiple photos for Front, Rear, Left, and Right views (Camera & Files supported)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 14),

                  _buildAngleSection('Front View'),
                  const SizedBox(height: 10),
                  _buildAngleSection('Rear View'),
                  const SizedBox(height: 10),
                  _buildAngleSection('Left Side'),
                  const SizedBox(height: 10),
                  _buildAngleSection('Right Side'),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.borderHairline),
                  const SizedBox(height: 16),

                  const Text('4. Customer Driving Licence & KYC Document Verification', style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  const Text('Capture or upload multiple documents for Driving Licence, Aadhaar, and identity verification (Camera & Files supported)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 14),

                  _buildCustomerKycHeader(),
                  const SizedBox(height: 12),

                  _buildDocSection('Driving Licence'),
                  const SizedBox(height: 10),
                  _buildDocSection('Aadhaar Card'),
                  const SizedBox(height: 10),
                  _buildDocSection('Additional Document'),
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
                      final odo = int.tryParse(_odometerController.text.trim());
                      if (odo == null || odo <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid starting odometer reading (KM)'),
                            backgroundColor: AppColors.criticalRed,
                          ),
                        );
                        return;
                      }

                      setState(() => _isLoading = true);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        // Collect all photos from all 4 angles into base64 payload
                        final Map<String, List<String>> photosPayload = {};
                        for (final entry in _photosByAngle.entries) {
                          if (entry.value.isNotEmpty) {
                            final list = entry.value.where((p) => p.base64 != null && p.base64!.isNotEmpty).map((p) => p.base64!).toList();
                            if (list.isNotEmpty) {
                              photosPayload[entry.key] = list;
                            }
                          }
                        }

                        // Also collect all uploaded KYC documents into base64 payload
                        for (final entry in _kycDocuments.entries) {
                          if (entry.value.isNotEmpty) {
                            final list = entry.value.where((p) => p.base64 != null && p.base64!.isNotEmpty).map((p) => p.base64!).toList();
                            if (list.isNotEmpty) {
                              photosPayload[entry.key] = list;
                            }
                          }
                        }

                        await ApiService().submitPickupInspection(
                          widget.bookingId,
                          startOdometer: odo,
                          fuelPercent: _fuelLevel,
                          notes: 'Verified accessories: spare wheel, tool kit, and registration documents checked.',
                          photosBase64: photosPayload.isNotEmpty ? photosPayload : null,
                        );
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Pickup completed! Trip is now Running.'),
                              backgroundColor: AppColors.successGreen,
                            ),
                          );
                          widget.onPickupConfirmed();
                        }
                      } catch (e) {
                        final msg = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(msg),
                              backgroundColor: AppColors.criticalRed,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isLoading = false);
                        }
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

  Future<void> _captureFromCamera(String angle) async {
    try {
      final file = await MediaPickerService.instance.captureImageWithCamera(
        context: context,
        title: '$angle Camera Photo',
        rationale: 'Camera access is required to capture $angle vehicle condition photo.',
      );

      if (file != null && mounted) {
        final bytes = await file.readAsBytes();
        final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _photosByAngle[angle]?.add(
            InspectionPhoto(bytes: bytes, base64: b64, name: file.name),
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Photo captured for $angle (Total: ${_photosByAngle[angle]?.length})'),
              backgroundColor: AppColors.successGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error capturing photo from camera: $e');
    }
  }

  Future<void> _pickFromGallery(String angle) async {
    try {
      final files = await MediaPickerService.instance.pickMultipleImagesFromGallery(
        context: context,
        title: 'Select $angle Photos',
        rationale: 'Photo library access is required to choose vehicle inspection photos.',
      );

      if (files.isNotEmpty && mounted) {
        int added = 0;
        for (final file in files) {
          final bytes = await file.readAsBytes();
          final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
          _photosByAngle[angle]?.add(
            InspectionPhoto(bytes: bytes, base64: b64, name: file.name),
          );
          added++;
        }
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ $added photo(s) added to $angle (Total: ${_photosByAngle[angle]?.length})'),
              backgroundColor: AppColors.successGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking photos from gallery: $e');
    }
  }

  void _showAddPhotoSheet(String angle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_angleIcons[angle] ?? Icons.camera_alt_rounded, color: AppColors.primaryCyan, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload $angle Photos',
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Capture live photo or upload multiple files from gallery',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: AppColors.canvasLow,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryCyan),
                ),
                title: const Text('Take Photo with Camera', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Open camera to capture vehicle condition', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                onTap: () {
                  Navigator.pop(ctx);
                  _captureFromCamera(angle);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: AppColors.canvasLow,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.successGreen),
                ),
                title: const Text('Choose from Files / Gallery', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Select multiple photos from device files or gallery', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromGallery(angle);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAngleSection(String angle) {
    final photos = _photosByAngle[angle] ?? [];
    final hasPhotos = photos.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hasPhotos ? AppColors.primaryCyan.withValues(alpha: 0.4) : AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(_angleIcons[angle] ?? Icons.directions_car_rounded, size: 18, color: hasPhotos ? AppColors.primaryCyan : AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    angle,
                    style: TextStyle(
                      color: hasPhotos ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: hasPhotos ? AppColors.successGreen.withValues(alpha: 0.15) : AppColors.surfaceHover,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: hasPhotos ? AppColors.successGreen.withValues(alpha: 0.3) : AppColors.borderSubtle),
                    ),
                    child: Text(
                      '${photos.length} ${photos.length == 1 ? "Photo" : "Photos"}',
                      style: TextStyle(
                        color: hasPhotos ? AppColors.successGreen : AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showAddPhotoSheet(angle),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_a_photo_rounded, size: 13, color: AppColors.primaryCyan),
                      SizedBox(width: 4),
                      Text('+ Add', style: TextStyle(color: AppColors.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (photos.isEmpty)
            InkWell(
              onTap: () => _showAddPhotoSheet(angle),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHover.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: AppColors.textMuted, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Tap to add photos (Camera & File upload)',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == photos.length) {
                    return InkWell(
                      onTap: () => _showAddPhotoSheet(angle),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 84,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHover,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryCyan, size: 22),
                            SizedBox(height: 4),
                            Text('Add More', style: TextStyle(color: AppColors.primaryCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  }

                  final photo = photos[index];
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (photo.bytes != null) {
                            AppPlaceholders.showImageBytesViewer(
                              context,
                              bytes: photo.bytes,
                              title: '$angle Photo #${index + 1}',
                            );
                          } else if (photo.url != null && photo.url!.isNotEmpty) {
                            AppPlaceholders.showImageViewer(
                              context,
                              imageUrl: photo.url!,
                              title: '$angle Photo #${index + 1}',
                            );
                          }
                        },
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: photo.bytes != null
                                ? Image.memory(
                                    photo.bytes!,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    photo.url!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Center(
                                      child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
                                    ),
                                    loadingBuilder: (_, child, progress) {
                                      if (progress == null) return child;
                                      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryCyan)));
                                    },
                                  ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _photosByAngle[angle]?.removeAt(index);
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.criticalRed,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerKycHeader() {
    final hasDocs = _totalKycDocsCount > 0 || (_booking?.customerKycStatus == 'verified');
    final dlNum = _booking?.customerDlNo ?? _booking?.kycDocNumber;
    final isDlPresent = dlNum != null && dlNum.isNotEmpty && dlNum != 'Verified';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.canvasLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hasDocs ? AppColors.successGreen.withValues(alpha: 0.3) : AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasDocs ? AppColors.successGreen.withValues(alpha: 0.15) : AppColors.surfaceHover,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: hasDocs ? AppColors.successGreen.withValues(alpha: 0.4) : AppColors.primaryCyan.withValues(alpha: 0.4)),
            ),
            child: Icon(
              hasDocs ? Icons.verified_user_rounded : Icons.badge_rounded,
              color: hasDocs ? AppColors.successGreen : AppColors.primaryCyan,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _booking?.customerName ?? 'Customer',
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: hasDocs ? AppColors.successGreen.withValues(alpha: 0.15) : AppColors.warningAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: hasDocs ? AppColors.successGreen.withValues(alpha: 0.3) : AppColors.warningAmber.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        hasDocs ? 'Verified' : 'Upload Required',
                        style: TextStyle(
                          color: hasDocs ? AppColors.successGreen : AppColors.warningAmber,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isDlPresent ? 'DL: $dlNum' : (_booking?.customerPhone.isNotEmpty == true ? 'Mobile: ${_booking!.customerPhone}' : 'Customer Verification'),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceHover,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.attach_file_rounded, size: 14, color: AppColors.primaryCyan),
                const SizedBox(width: 4),
                Text(
                  '$_totalKycDocsCount ${_totalKycDocsCount == 1 ? "Doc" : "Docs"}',
                  style: const TextStyle(color: AppColors.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureDocFromCamera(String docType) async {
    try {
      final file = await MediaPickerService.instance.captureImageWithCamera(
        context: context,
        title: '$docType Camera Photo',
        rationale: 'Camera access is required to capture customer $docType verification photo.',
      );

      if (file != null && mounted) {
        final bytes = await file.readAsBytes();
        final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _kycDocuments[docType]?.add(
            InspectionPhoto(bytes: bytes, base64: b64, name: file.name),
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ $docType photo captured (Total: ${_kycDocuments[docType]?.length})'),
              backgroundColor: AppColors.successGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error capturing $docType photo: $e');
    }
  }

  Future<void> _pickDocFromGallery(String docType) async {
    try {
      final files = await MediaPickerService.instance.pickMultipleImagesFromGallery(
        context: context,
        title: 'Select $docType Photos',
        rationale: 'Photo library access is required to choose $docType verification photos.',
      );

      if (files.isNotEmpty && mounted) {
        int added = 0;
        for (final file in files) {
          final bytes = await file.readAsBytes();
          final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
          _kycDocuments[docType]?.add(
            InspectionPhoto(bytes: bytes, base64: b64, name: file.name),
          );
          added++;
        }
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ $added document photo(s) added to $docType (Total: ${_kycDocuments[docType]?.length})'),
              backgroundColor: AppColors.successGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking $docType photos from gallery: $e');
    }
  }

  void _showAddDocSheet(String docType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_kycDocIcons[docType] ?? Icons.badge_rounded, color: AppColors.primaryCyan, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload $docType',
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Capture live photo or upload multiple files from gallery',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: AppColors.canvasLow,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryCyan),
                ),
                title: const Text('Take Photo with Camera', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('Open camera to capture $docType (Front/Back)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                onTap: () {
                  Navigator.pop(ctx);
                  _captureDocFromCamera(docType);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: AppColors.canvasLow,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.successGreen),
                ),
                title: const Text('Choose from Files / Gallery', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Select multiple documents from device gallery or files', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickDocFromGallery(docType);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocSection(String docType) {
    final photos = _kycDocuments[docType] ?? [];
    final hasPhotos = photos.isNotEmpty;
    final icon = _kycDocIcons[docType] ?? Icons.badge_rounded;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hasPhotos ? AppColors.primaryCyan.withValues(alpha: 0.4) : AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: hasPhotos ? AppColors.primaryCyan : AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    docType,
                    style: TextStyle(
                      color: hasPhotos ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: hasPhotos ? AppColors.successGreen.withValues(alpha: 0.15) : AppColors.surfaceHover,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: hasPhotos ? AppColors.successGreen.withValues(alpha: 0.3) : AppColors.borderSubtle),
                    ),
                    child: Text(
                      '${photos.length} ${photos.length == 1 ? "Doc" : "Docs"}',
                      style: TextStyle(
                        color: hasPhotos ? AppColors.successGreen : AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showAddDocSheet(docType),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_a_photo_rounded, size: 13, color: AppColors.primaryCyan),
                      SizedBox(width: 4),
                      Text('+ Add', style: TextStyle(color: AppColors.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (photos.isEmpty)
            InkWell(
              onTap: () => _showAddDocSheet(docType),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHover.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textMuted, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Tap to upload $docType (Camera & Files supported)',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == photos.length) {
                    return InkWell(
                      onTap: () => _showAddDocSheet(docType),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 84,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHover,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryCyan, size: 22),
                            SizedBox(height: 4),
                            Text('Add More', style: TextStyle(color: AppColors.primaryCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  }

                  final photo = photos[index];
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (photo.bytes != null) {
                            AppPlaceholders.showImageBytesViewer(
                              context,
                              bytes: photo.bytes,
                              title: '$docType Doc #${index + 1}',
                            );
                          } else if (photo.url != null && photo.url!.isNotEmpty) {
                            AppPlaceholders.showImageViewer(
                              context,
                              imageUrl: photo.url!,
                              title: '$docType Doc #${index + 1}',
                            );
                          }
                        },
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: photo.bytes != null
                                ? Image.memory(
                                    photo.bytes!,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    photo.url!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Center(
                                      child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
                                    ),
                                    loadingBuilder: (_, child, progress) {
                                      if (progress == null) return child;
                                      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryCyan)));
                                    },
                                  ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _kycDocuments[docType]?.removeAt(index);
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.criticalRed,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
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
