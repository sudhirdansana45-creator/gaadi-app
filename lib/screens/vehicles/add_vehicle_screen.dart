import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/api_config.dart';
import '../../core/media/media_picker_service.dart';
import '../../core/services/vehicle_draft_service.dart';
import '../../models/mock_models.dart';
import '../../theme/app_colors.dart';
import '../../services/api_service.dart';
import 'widgets/vehicle_image_cropper_dialog.dart';

class AddVehicleScreen extends StatefulWidget {
  final VoidCallback onSaved;
  final VoidCallback onCancel;
  final Vehicle? vehicleToEdit;
  final String? vehicleId;

  const AddVehicleScreen({
    super.key,
    required this.onSaved,
    required this.onCancel,
    this.vehicleToEdit,
    this.vehicleId,
  });

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  String _selectedCategory = 'car'; // 'car' or 'bike'
  String _selectedFuel = 'Petrol';
  String _ownershipMode = 'own'; // 'own' or 'partner'
  
  final _nameController = TextEditingController();
  final _regController = TextEditingController();
  final _mfgYearController = TextEditingController();
  final _colorController = TextEditingController();
  
  final _hourlyRateCtrl = TextEditingController();
  final _dailyRateCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _extraKmCtrl = TextEditingController();

  final _partnerNameCtrl = TextEditingController();
  final _expiryDateCtrl = TextEditingController();

  final _scrollController = ScrollController();

  bool _isEditing = false;
  bool _isLoading = false;
  bool _isFetchingDetails = false;
  bool _dailyRateHasError = false;

  // Dynamic drafts
  int _draftsCount = 0;
  String? _currentDraftId;

  // Image states
  Uint8List? _selectedImageBytes;
  String? _existingImageUrl;
  String? _imageBase64;

  // RC Document states
  Uint8List? _rcImageBytes;
  String? _rcExistingUrl;
  String? _rcImageBase64;
  String? _rcFileName;

  @override
  void initState() {
    super.initState();
    _loadDraftsCount();

    _dailyRateCtrl.addListener(() {
      if (_dailyRateHasError && _dailyRateCtrl.text.trim().isNotEmpty) {
        setState(() => _dailyRateHasError = false);
      }
    });

    if (widget.vehicleToEdit != null) {
      _initFromVehicle(widget.vehicleToEdit!);
    } else if (widget.vehicleId != null && widget.vehicleId!.isNotEmpty) {
      _fetchVehicleDetail(widget.vehicleId!);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _regController.dispose();
    _mfgYearController.dispose();
    _colorController.dispose();
    _hourlyRateCtrl.dispose();
    _dailyRateCtrl.dispose();
    _depositCtrl.dispose();
    _extraKmCtrl.dispose();
    _partnerNameCtrl.dispose();
    _expiryDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDraftsCount() async {
    final count = await VehicleDraftService.instance.getDraftsCount();
    if (mounted) {
      setState(() => _draftsCount = count);
    }
  }

  Future<void> _handleSaveDraft() async {
    final name = _nameController.text.trim();
    final regNo = _regController.text.trim();
    final draftTitle = name.isNotEmpty ? name : (regNo.isNotEmpty ? regNo : 'Draft Vehicle');

    final draft = {
      'id': _currentDraftId ?? 'draft_${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'number': regNo,
      'category': _selectedCategory,
      'fuel_type': _selectedFuel,
      'ownership': _ownershipMode,
      'daily_rate': _dailyRateCtrl.text.trim(),
      'hourly_rate': _hourlyRateCtrl.text.trim(),
      'deposit': _depositCtrl.text.trim(),
      'extra_km': _extraKmCtrl.text.trim(),
      'color': _colorController.text.trim(),
      'year': _mfgYearController.text.trim(),
      'partner_name': _partnerNameCtrl.text.trim(),
      'image_base64': _imageBase64,
      'rc_image_base64': _rcImageBase64,
      'insurance_expiry_date': _expiryDateCtrl.text.trim(),
    };

    await VehicleDraftService.instance.saveDraft(draft);
    _currentDraftId = draft['id'];
    await _loadDraftsCount();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF1BBD85)),
              const SizedBox(width: 8),
              Expanded(child: Text('Draft saved: $draftTitle')),
            ],
          ),
          backgroundColor: const Color(0xFF252A36),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showDraftsModal(BuildContext context) async {
    final drafts = await VehicleDraftService.instance.getDrafts();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return SafeArea(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.folder_open_rounded, color: AppColors.primaryCyan, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Saved Drafts (${drafts.length})',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (drafts.isNotEmpty)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.criticalRed,
                          ),
                          onPressed: () async {
                            await VehicleDraftService.instance.clearAllDrafts();
                            await _loadDraftsCount();
                            setModalState(() => drafts.clear());
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                          label: const Text('Clear All', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (drafts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Column(
                        children: [
                          Icon(Icons.drafts_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          const Text(
                            'No saved drafts yet',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Use "Save Draft" at bottom to save in-progress entries.',
                            style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: drafts.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final d = drafts[index];
                          final title = (d['name'] != null && (d['name'] as String).isNotEmpty)
                              ? d['name']
                              : (d['number'] != null && (d['number'] as String).isNotEmpty ? d['number'] : 'Untitled Draft');
                          final category = d['category'] ?? 'car';
                          final rate = d['daily_rate'] ?? '';
                          final date = d['updated_at'] != null ? DateTime.tryParse(d['updated_at']) : null;
                          final dateStr = date != null ? '${date.day}/${date.month}/${date.year}' : '';

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF171B27),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x1AFFFFFF)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    category == 'bike' ? Icons.two_wheeler_rounded : Icons.directions_car_rounded,
                                    color: AppColors.primaryCyan,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${d['number'] ?? ''} ${rate.toString().isNotEmpty ? '• ₹$rate/day' : ''} ${dateStr.isNotEmpty ? '• $dateStr' : ''}',
                                        style: const TextStyle(color: Color(0xFF869397), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.file_download_outlined, color: AppColors.primaryCyan),
                                  tooltip: 'Load Draft',
                                  onPressed: () {
                                    _loadFromDraft(d);
                                    Navigator.pop(ctx);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.criticalRed, size: 20),
                                  tooltip: 'Delete',
                                  onPressed: () async {
                                    await VehicleDraftService.instance.deleteDraft(d['id']);
                                    await _loadDraftsCount();
                                    setModalState(() {
                                      drafts.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _loadFromDraft(Map<String, dynamic> d) {
    setState(() {
      _currentDraftId = d['id'];
      _nameController.text = d['name'] ?? '';
      _regController.text = d['number'] ?? '';
      _selectedCategory = d['category'] ?? 'car';
      _selectedFuel = d['fuel_type'] ?? 'Petrol';
      _ownershipMode = d['ownership'] ?? 'own';
      _dailyRateCtrl.text = d['daily_rate'] ?? '';
      _hourlyRateCtrl.text = d['hourly_rate'] ?? '';
      _depositCtrl.text = d['deposit'] ?? '';
      _extraKmCtrl.text = d['extra_km'] ?? '';
      _colorController.text = d['color'] ?? '';
      _mfgYearController.text = d['year'] ?? '';
      _partnerNameCtrl.text = d['partner_name'] ?? '';
      if (d['image_base64'] != null) {
        _imageBase64 = d['image_base64'];
        try {
          final commaIdx = _imageBase64!.indexOf(',');
          final b64Str = commaIdx >= 0 ? _imageBase64!.substring(commaIdx + 1) : _imageBase64!;
          _selectedImageBytes = base64Decode(b64Str);
        } catch (_) {}
      }
      if (d['rc_image_base64'] != null) {
        _rcImageBase64 = d['rc_image_base64'];
        _rcFileName = 'RC_Draft_Document.jpg';
        try {
          final commaIdx = _rcImageBase64!.indexOf(',');
          final b64Str = commaIdx >= 0 ? _rcImageBase64!.substring(commaIdx + 1) : _rcImageBase64!;
          _rcImageBytes = base64Decode(b64Str);
        } catch (_) {}
      }
      if (d['insurance_expiry_date'] != null) {
        _expiryDateCtrl.text = d['insurance_expiry_date'];
      }
      _dailyRateHasError = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Draft "${_nameController.text.isNotEmpty ? _nameController.text : "Vehicle"}" loaded!'),
        backgroundColor: const Color(0xFF252A36),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _initFromVehicle(Vehicle v) {
    _isEditing = true;
    _nameController.text = v.name;
    _regController.text = v.regNumber;
    _colorController.text = v.color;
    if (v.year.isNotEmpty) {
      _mfgYearController.text = v.year;
    }
    _selectedCategory = (v.category.toLowerCase().contains('bike') || v.category.toLowerCase().contains('scooter')) ? 'bike' : 'car';
    _selectedFuel = v.fuelType.isNotEmpty ? v.fuelType : 'Petrol';
    _dailyRateCtrl.text = v.dailyRate > 0 ? v.dailyRate.toInt().toString() : '';
    _hourlyRateCtrl.text = v.hourlyRate > 0 ? v.hourlyRate.toInt().toString() : '';
    _depositCtrl.text = v.securityDeposit > 0 ? v.securityDeposit.toInt().toString() : '';
    _partnerNameCtrl.text = (v.assignedPartner != 'Direct Fleet' && v.assignedPartner.isNotEmpty) ? v.assignedPartner : '';
    _existingImageUrl = v.imageUrl.isNotEmpty ? ApiConfig.resolveImageUrl(v.imageUrl) : null;
    if (v.insuranceExpiryDate != null && v.insuranceExpiryDate!.isNotEmpty) {
      _expiryDateCtrl.text = v.insuranceExpiryDate!;
    }
    if (v.rcImageUrl != null && v.rcImageUrl!.isNotEmpty) {
      _rcExistingUrl = ApiConfig.resolveImageUrl(v.rcImageUrl);
      _rcFileName = 'RC_Front_Document.jpg';
    }
  }

  Future<void> _fetchVehicleDetail(String id) async {
    setState(() => _isFetchingDetails = true);
    try {
      final res = await ApiService().getVehicleDetail(id);
      if (res != null && res['data'] != null && mounted) {
        final v = Vehicle.fromJson(res['data'] as Map<String, dynamic>);
        setState(() {
          _initFromVehicle(v);
        });
      }
    } catch (e) {
      debugPrint('Error loading vehicle detail: $e');
    } finally {
      if (mounted) {
        setState(() => _isFetchingDetails = false);
      }
    }
  }

  void _notifyPhotoSaved(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF003640), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Color(0xFF003640), fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF06B6D4),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _showImagePickerOptions() async {
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
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Upload Vehicle Photo',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select camera or gallery to add vehicle photo',
                style: TextStyle(color: Color(0xFF869397), fontSize: 12),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryCyan),
                ),
                title: const Text('Take Photo with Camera', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: const Text('Capture photo and adjust crop frame', style: TextStyle(color: Color(0xFF869397), fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await MediaPickerService.instance.captureImageWithCamera(
                    context: context,
                    title: 'Vehicle Camera Photo',
                    rationale: 'Camera access is required to take photos of your fleet vehicles.',
                  );
                  if (file != null && mounted) {
                    final rawBytes = await file.readAsBytes();
                    if (mounted) {
                      final croppedBytes = await VehicleImageCropperDialog.show(context, rawBytes);
                      if (croppedBytes != null && mounted) {
                        setState(() {
                          _selectedImageBytes = croppedBytes;
                          _imageBase64 = 'data:image/jpeg;base64,${base64Encode(croppedBytes)}';
                        });
                        _notifyPhotoSaved('Vehicle photo cropped and added!');
                      }
                    }
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4EDEAE).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF4EDEAE)),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: const Text('Select existing photo and adjust crop frame', style: TextStyle(color: Color(0xFF869397), fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await MediaPickerService.instance.pickImageFromGallery(
                    context: context,
                    title: 'Select Vehicle Photo',
                    rationale: 'Photo library access is needed to select vehicle images.',
                  );
                  if (file != null && mounted) {
                    final rawBytes = await file.readAsBytes();
                    if (mounted) {
                      final croppedBytes = await VehicleImageCropperDialog.show(context, rawBytes);
                      if (croppedBytes != null && mounted) {
                        setState(() {
                          _selectedImageBytes = croppedBytes;
                          _imageBase64 = 'data:image/jpeg;base64,${base64Encode(croppedBytes)}';
                        });
                        _notifyPhotoSaved('Vehicle photo cropped and added!');
                      }
                    }
                  }
                },
              ),
              if (_selectedImageBytes != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.crop_rotate_rounded, color: Color(0xFFF59E0B)),
                  ),
                  title: const Text('Re-crop / Adjust Current Photo', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Adjust frame ratio or zoom for this vehicle', style: TextStyle(color: Color(0xFF869397), fontSize: 11)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final croppedBytes = await VehicleImageCropperDialog.show(context, _selectedImageBytes!);
                    if (croppedBytes != null && mounted) {
                      setState(() {
                        _selectedImageBytes = croppedBytes;
                        _imageBase64 = 'data:image/jpeg;base64,${base64Encode(croppedBytes)}';
                      });
                      _notifyPhotoSaved('Vehicle photo adjusted and saved!');
                    }
                  },
                ),
              if (_selectedImageBytes != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty))
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.criticalRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.criticalRed),
                  ),
                  title: const Text('Remove Photo', style: TextStyle(color: AppColors.criticalRed, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _selectedImageBytes = null;
                      _existingImageUrl = null;
                      _imageBase64 = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRcPickerOptions() async {
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
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Upload RC Book / Smart Card',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Take photo or choose from gallery to upload vehicle registration card',
                style: TextStyle(color: Color(0xFF869397), fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF06B6D4)),
                ),
                title: const Text('Take Photo with Camera', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: const Text('Capture clear photo of RC front / smart card', style: TextStyle(color: Color(0xFF869397), fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await MediaPickerService.instance.captureImageWithCamera(
                    context: context,
                    title: 'Vehicle RC Document',
                    rationale: 'Camera access is required to capture vehicle RC document.',
                  );
                  if (file != null && mounted) {
                    final rawBytes = await file.readAsBytes();
                    if (mounted) {
                      final croppedBytes = await VehicleImageCropperDialog.show(context, rawBytes);
                      if (croppedBytes != null && mounted) {
                        final regClean = _regController.text.trim().replaceAll(' ', '_');
                        setState(() {
                          _rcImageBytes = croppedBytes;
                          _rcImageBase64 = 'data:image/jpeg;base64,${base64Encode(croppedBytes)}';
                          _rcFileName = regClean.isNotEmpty ? '${regClean}_RC_Front.jpg' : 'RC_Front_Document.jpg';
                        });
                        _notifyPhotoSaved('RC document photo cropped and added!');
                      }
                    }
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4EDEAE).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF4EDEAE)),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: const Text('Select RC document image from gallery', style: TextStyle(color: Color(0xFF869397), fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await MediaPickerService.instance.pickImageFromGallery(
                    context: context,
                    title: 'Select RC Document',
                    rationale: 'Photo library access is needed to select vehicle RC card.',
                  );
                  if (file != null && mounted) {
                    final rawBytes = await file.readAsBytes();
                    if (mounted) {
                      final croppedBytes = await VehicleImageCropperDialog.show(context, rawBytes);
                      if (croppedBytes != null && mounted) {
                        final regClean = _regController.text.trim().replaceAll(' ', '_');
                        setState(() {
                          _rcImageBytes = croppedBytes;
                          _rcImageBase64 = 'data:image/jpeg;base64,${base64Encode(croppedBytes)}';
                          _rcFileName = regClean.isNotEmpty ? '${regClean}_RC_Front.jpg' : 'RC_Front_Document.jpg';
                        });
                        _notifyPhotoSaved('RC document photo cropped and added!');
                      }
                    }
                  }
                },
              ),
              if (_rcImageBytes != null || (_rcExistingUrl != null && _rcExistingUrl!.isNotEmpty))
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.criticalRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.criticalRed),
                  ),
                  title: const Text('Remove RC Document', style: TextStyle(color: AppColors.criticalRed, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _rcImageBytes = null;
                      _rcImageBase64 = null;
                      _rcExistingUrl = null;
                      _rcFileName = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectPolicyExpiryDate() async {
    DateTime initial = DateTime.now().add(const Duration(days: 365));
    if (_expiryDateCtrl.text.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(_expiryDateCtrl.text.trim());
      if (parsed != null) {
        initial = parsed;
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2045),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF06B6D4),
              onPrimary: Color(0xFF090E19),
              surface: Color(0xFF171B27),
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF171B27),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final formatted = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _expiryDateCtrl.text = formatted;
      });
    }
  }

  Future<void> _handlePublish() async {
    final regNo = _regController.text.trim();
    final name = _nameController.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    if (name.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please enter vehicle brand & model'),
          backgroundColor: AppColors.criticalRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (regNo.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please enter registration plate number'),
          backgroundColor: AppColors.criticalRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final dailyRateText = _dailyRateCtrl.text.trim();
    final dailyRateVal = double.tryParse(dailyRateText);
    if (dailyRateText.isEmpty || dailyRateVal == null || dailyRateVal <= 0) {
      setState(() => _dailyRateHasError = true);
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Daily rental rate is mandatory! Please enter amount (e.g. ₹1500)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.criticalRed,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
      _scrollController.animateTo(
        260,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payload = <String, dynamic>{
        'name': name,
        'number': regNo,
        'type': _selectedCategory,
        'category': _selectedCategory == 'bike' ? 'Bike' : 'Car',
        'fuel_type': _selectedFuel,
        'daily_rate': dailyRateVal,
        'hourly_rate': _hourlyRateCtrl.text.trim().isNotEmpty ? (double.tryParse(_hourlyRateCtrl.text.trim()) ?? 0) : 0,
        'security_deposit': _depositCtrl.text.trim().isNotEmpty ? (double.tryParse(_depositCtrl.text.trim()) ?? 0) : 0,
        'extra_km_rate': _extraKmCtrl.text.trim().isNotEmpty ? (double.tryParse(_extraKmCtrl.text.trim()) ?? 0) : 0,
        'color': _colorController.text.trim().isNotEmpty ? _colorController.text.trim() : 'White',
        'year': _mfgYearController.text.trim(),
        'rc_number': regNo,
      };
      if (_expiryDateCtrl.text.trim().isNotEmpty) {
        payload['insurance_expiry_date'] = _expiryDateCtrl.text.trim();
      }
      if (_imageBase64 != null) {
        payload['image_base64'] = _imageBase64;
      } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
        payload['image_url'] = _existingImageUrl;
      }
      if (_rcImageBase64 != null) {
        payload['rc_image_base64'] = _rcImageBase64;
      } else if (_rcExistingUrl != null && _rcExistingUrl!.isNotEmpty) {
        payload['rc_image_url'] = _rcExistingUrl;
      }

      if (_isEditing) {
        final targetId = widget.vehicleToEdit?.id ?? widget.vehicleId!;
        await ApiService().updateVehicle(targetId, payload);
        if (_currentDraftId != null) {
          await VehicleDraftService.instance.deleteDraft(_currentDraftId!);
          await _loadDraftsCount();
        }
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('✅ Vehicle $regNo updated successfully!'),
              backgroundColor: const Color(0xFF1BBD85),
              duration: const Duration(seconds: 2),
            ),
          );
          widget.onSaved();
        }
      } else {
        await ApiService().createVehicle(fields: payload);
        if (_currentDraftId != null) {
          await VehicleDraftService.instance.deleteDraft(_currentDraftId!);
          await _loadDraftsCount();
        }
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('🚀 Vehicle $regNo live on fleet!'),
              backgroundColor: const Color(0xFF06B6D4),
              duration: const Duration(seconds: 2),
            ),
          );
          widget.onSaved();
        }
      }
    } catch (e) {
      final msg = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.criticalRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetchingDetails) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryCyan),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sub-Header Navigation / Helper Strip
                    _buildSubHeaderStrip(context),
                    const SizedBox(height: 12),

                    // Section 1: Vehicle Category Switcher (Car vs Bike)
                    _buildCategorySwitcher(context),
                    const SizedBox(height: 14),

                    // Visual Asset Showcase Banner
                    _buildShowcaseBanner(context),
                    const SizedBox(height: 16),

                    // Section 2: Identity & Specs Card
                    _buildIdentityAndSpecsCard(context),
                    const SizedBox(height: 16),

                    // Section 3: Rental Pricing & Tariff (Bento Matrix)
                    _buildTariffBentoCard(context),
                    const SizedBox(height: 16),

                    // Section 4: Fleet Ownership Structure
                    _buildOwnershipCard(context),
                    const SizedBox(height: 16),

                    // Section 5: Vehicle Documents
                    _buildDocumentsCard(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Floating Sticky Action Deck
            _buildStickyActionDeck(context),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUB-HEADER HELPER STRIP
  // ---------------------------------------------------------------------------
  Widget _buildSubHeaderStrip(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            InkWell(
              onTap: widget.onCancel,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 16),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _isEditing ? 'Edit Vehicle' : 'Vehicle Form',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF252A36),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Row(
                children: [
                  CircleAvatar(radius: 3, backgroundColor: Color(0xFF4EDEAE)),
                  SizedBox(width: 6),
                  Text(
                    'Auto-saving',
                    style: TextStyle(
                      color: Color(0xFF4EDEAE),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showDraftsModal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF252A36),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _draftsCount > 0 ? const Color(0xFF4CD7F6).withValues(alpha: 0.5) : const Color(0x1AFFFFFF),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder_open_rounded, color: Color(0xFF4CD7F6), size: 15),
                    const SizedBox(width: 4),
                    Text(
                      'Drafts ($_draftsCount)',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 1. VEHICLE CATEGORY SWITCHER
  // ---------------------------------------------------------------------------
  Widget _buildCategorySwitcher(BuildContext context) {
    final isCar = _selectedCategory == 'car';
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF171B27),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = 'car';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isCar ? const Color(0xFF1B1F2B) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isCar
                      ? const [
                          BoxShadow(
                            color: Color(0x59000000),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_car_rounded,
                      color: isCar ? const Color(0xFF4CD7F6) : const Color(0xFFBCC9CD),
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Car / SUV',
                      style: TextStyle(
                        color: isCar ? const Color(0xFF4CD7F6) : const Color(0xFFBCC9CD),
                        fontSize: 14,
                        fontWeight: isCar ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = 'bike';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isCar ? const Color(0xFF1B1F2B) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !isCar
                      ? const [
                          BoxShadow(
                            color: Color(0x59000000),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.two_wheeler_rounded,
                      color: !isCar ? const Color(0xFF4CD7F6) : const Color(0xFFBCC9CD),
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Bike / Scooter',
                      style: TextStyle(
                        color: !isCar ? const Color(0xFF4CD7F6) : const Color(0xFFBCC9CD),
                        fontSize: 14,
                        fontWeight: !isCar ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SHOWCASE BANNER
  // ---------------------------------------------------------------------------
  Widget _buildShowcaseBanner(BuildContext context) {
    final bool hasMemoryImage = _selectedImageBytes != null;
    final bool hasExistingImage = _existingImageUrl != null && _existingImageUrl!.isNotEmpty;
    final bool hasAnyImage = hasMemoryImage || hasExistingImage;

    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: Container(
        height: 160,
        width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF171B27),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasAnyImage ? const Color(0xFF2A3854).withValues(alpha: 0.6) : const Color(0xFF06B6D4).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasMemoryImage)
              Image.memory(
                _selectedImageBytes!,
                fit: BoxFit.cover,
              )
            else if (hasExistingImage)
              Image.network(
                ApiConfig.resolveImageUrl(_existingImageUrl!),
                fit: BoxFit.cover,
                errorBuilder: (context, err, stack) => _buildImagePlaceholder(),
              )
            else
              _buildImagePlaceholder(),

            // Gradient Overlay for text readability
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xCC0E131E), Color(0x330E131E), Color(0xDD0E131E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Top Status Badges
            Positioned(
              top: 12,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E131E).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isEditing ? Icons.edit_note_rounded : Icons.add_photo_alternate_rounded,
                          color: const Color(0xFF4CD7F6),
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isEditing ? 'EDITING VEHICLE' : 'VEHICLE PHOTO',
                          style: const TextStyle(
                            color: Color(0xFF4CD7F6),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasAnyImage)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1BBD85).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'PHOTO ATTACHED',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Actions & Info
            Positioned(
              bottom: 12,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _nameController.text.trim().isNotEmpty
                              ? _nameController.text.trim()
                              : (_isEditing ? 'Update Vehicle' : 'Vehicle Profile Setup'),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasAnyImage ? 'Tap button to change photo' : 'Upload front or 3/4 angle photo',
                          style: const TextStyle(
                            color: Color(0xFFBCC9CD),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06B6D4),
                      foregroundColor: const Color(0xFF003640),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 4,
                    ),
                    onPressed: _showImagePickerOptions,
                    icon: Icon(
                      hasAnyImage ? Icons.edit_rounded : Icons.camera_alt_rounded,
                      size: 16,
                      color: const Color(0xFF003640),
                    ),
                    label: Text(
                      hasAnyImage ? 'Change' : 'Upload',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF003640),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E2433), Color(0xFF141824)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.3)),
              ),
              child: Icon(
                _selectedCategory == 'bike' ? Icons.two_wheeler_rounded : Icons.directions_car_rounded,
                color: const Color(0xFF4CD7F6),
                size: 32,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'No Vehicle Photo Added',
              style: TextStyle(color: Color(0xFF869397), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. IDENTITY & SPECS CARD
  // ---------------------------------------------------------------------------
  Widget _buildIdentityAndSpecsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3854).withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.badge_rounded, color: Color(0xFF4CD7F6), size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Identity & Specs',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1BBD85).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'RTO COMPLIANT',
                  style: TextStyle(
                    color: Color(0xFF4EDEAE),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Vehicle Model Field
          const Text(
            'Vehicle Brand & Model',
            style: TextStyle(color: Color(0xFFBCC9CD), fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. Royal Enfield Meteor 350 / Mahindra Thar',
              hintStyle: const TextStyle(color: Color(0xFF869397), fontSize: 13),
              prefixIcon: const Icon(Icons.directions_car_rounded, color: Color(0xFF869397), size: 20),
              filled: true,
              fillColor: const Color(0xFF171B27),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Registration Plate (HSRP Format)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Registration Plate (HSRP Format)',
                style: TextStyle(color: Color(0xFFBCC9CD), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const Text(
                'Live Vahan Link',
                style: TextStyle(color: Color(0xFF4EDEAE), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // High-detail Indian Plate Box
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF171B27),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Left IND Strip
                Container(
                  width: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF303541),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'IND',
                        style: TextStyle(
                          color: Color(0xFF4CD7F6),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text('🇮🇳', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: _regController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        color: Color(0xFF4CD7F6),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontFamily: 'monospace',
                      ),
                      decoration: const InputDecoration(
                        hintText: 'KA 05 MN 4410',
                        hintStyle: TextStyle(color: Color(0xFF869397), fontSize: 16),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.check_circle_rounded, color: Color(0xFF4EDEAE), size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2 Columns: Mfg Year & Color Shade
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mfg Year', style: TextStyle(color: Color(0xFFBCC9CD), fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _mfgYearController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.calendar_today_rounded, color: Color(0xFF869397), size: 18),
                        filled: true,
                        fillColor: const Color(0xFF171B27),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Color Shade', style: TextStyle(color: Color(0xFFBCC9CD), fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _colorController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.palette_rounded, color: Color(0xFF869397), size: 18),
                        filled: true,
                        fillColor: const Color(0xFF171B27),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Fuel Type Chips
          const Text('Powertrain / Fuel Variant', style: TextStyle(color: Color(0xFFBCC9CD), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              _fuelChip('Petrol', Icons.local_gas_station_rounded),
              const SizedBox(width: 6),
              _fuelChip('Diesel', Icons.opacity_rounded),
              const SizedBox(width: 6),
              _fuelChip('Electric', Icons.bolt_rounded),
              const SizedBox(width: 6),
              _fuelChip('CNG', Icons.propane_tank_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fuelChip(String label, IconData icon) {
    final isSelected = _selectedFuel == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFuel = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF171B27),
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? const [BoxShadow(color: Color(0x6606B6D4), blurRadius: 10, offset: Offset(0, 3))]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF003640) : const Color(0xFFBCC9CD), size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF003640) : const Color(0xFFBCC9CD),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. TARIFF & SECURITY RATES (BENTO MATRIX)
  // ---------------------------------------------------------------------------
  Widget _buildTariffBentoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3854).withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.currency_rupee_rounded, color: Color(0xFF4CD7F6), size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Tariff & Security Rates',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0566D9).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'UPI READY',
                  style: TextStyle(
                    color: Color(0xFFADC6FF),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2x2 Bento Matrix
          Row(
            children: [
              Expanded(
                child: _bentoTile(
                  title: 'Hourly Rate',
                  rightBadge: null,
                  rightIcon: Icons.schedule_rounded,
                  ctrl: _hourlyRateCtrl,
                  currencyColor: const Color(0xFF4CD7F6),
                  footerText: 'PER HOUR CHARGE',
                  footerColor: const Color(0xFF869397),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _bentoTile(
                  title: 'Daily Tariff *',
                  rightBadge: _dailyRateHasError ? 'REQUIRED' : 'MANDATORY',
                  rightIcon: null,
                  ctrl: _dailyRateCtrl,
                  currencyColor: const Color(0xFF4CD7F6),
                  footerText: _dailyRateHasError ? '* ENTER AMOUNT' : 'REQUIRED (PER 24H)',
                  footerColor: const Color(0xFFF87171),
                  hasError: _dailyRateHasError,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _bentoTile(
                  title: 'Caution Money',
                  rightBadge: null,
                  rightIcon: Icons.verified_user_rounded,
                  ctrl: _depositCtrl,
                  currencyColor: const Color(0xFF4EDEAE),
                  footerText: '100% REFUNDABLE',
                  footerColor: const Color(0xFF4EDEAE),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _bentoTile(
                  title: 'Over-limit Km',
                  rightBadge: null,
                  rightIcon: Icons.speed_rounded,
                  ctrl: _extraKmCtrl,
                  currencyColor: const Color(0xFF4CD7F6),
                  footerText: 'PER EXCESS KM',
                  footerColor: const Color(0xFF869397),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bentoTile({
    required String title,
    required String? rightBadge,
    required IconData? rightIcon,
    required TextEditingController ctrl,
    required Color currencyColor,
    required String footerText,
    required Color footerColor,
    bool hasError = false,
  }) {
    final bool isMandatory = rightBadge == 'MANDATORY' || hasError;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171B27),
        borderRadius: BorderRadius.circular(12),
        border: hasError
            ? Border.all(color: const Color(0xFFEF4444), width: 1.8)
            : (isMandatory ? Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3), width: 1) : null),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFFBCC9CD), fontSize: 11)),
              if (rightBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isMandatory ? const Color(0xFFEF4444).withValues(alpha: 0.2) : const Color(0xFF1BBD85).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    rightBadge,
                    style: TextStyle(
                      color: isMandatory ? const Color(0xFFF87171) : const Color(0xFF4EDEAE),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (rightIcon != null)
                Icon(rightIcon, color: currencyColor, size: 14),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹',
                style: TextStyle(
                  color: currencyColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            footerText,
            style: TextStyle(
              color: footerColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. FLEET OWNERSHIP STRUCTURE
  // ---------------------------------------------------------------------------
  Widget _buildOwnershipCard(BuildContext context) {
    final isPartner = _ownershipMode == 'partner';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3854).withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.real_estate_agent_rounded, color: Color(0xFF4CD7F6), size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Ownership & Payouts',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                'Financial Model',
                style: TextStyle(color: Color(0xFFBCC9CD), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Segmented Ownership Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF171B27),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _ownershipMode = 'own'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !isPartner ? const Color(0xFF1B1F2B) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.storefront_rounded, color: !isPartner ? const Color(0xFF4CD7F6) : const Color(0xFFBCC9CD), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Own Fleet (100%)',
                            style: TextStyle(
                              color: !isPartner ? const Color(0xFF4CD7F6) : const Color(0xFFBCC9CD),
                              fontSize: 12,
                              fontWeight: !isPartner ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _ownershipMode = 'partner'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isPartner ? const Color(0xFF1B1F2B) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.handshake_rounded, color: isPartner ? const Color(0xFF4CD7F6) : const Color(0xFFBCC9CD), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Partner Attached',
                            style: TextStyle(
                              color: isPartner ? const Color(0xFF4CD7F6) : const Color(0xFFBCC9CD),
                              fontSize: 12,
                              fontWeight: isPartner ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isPartner) ...[
            const SizedBox(height: 14),
            const Text('Partner / Investor Full Name', style: TextStyle(color: Color(0xFFBCC9CD), fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _partnerNameCtrl,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF869397), size: 20),
                filled: true,
                fillColor: const Color(0xFF171B27),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Revenue Share Split', style: TextStyle(color: Color(0xFFBCC9CD), fontSize: 12, fontWeight: FontWeight.w600)),
                const Text('75% Owner / 25% Shop', style: TextStyle(color: Color(0xFF4CD7F6), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF171B27),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Car Owner Payout', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                      Text('75%', style: TextStyle(color: Color(0xFF4CD7F6), fontSize: 18, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress Bar Split (75% Cyan / 25% Blue)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          Expanded(flex: 75, child: Container(color: const Color(0xFF06B6D4))),
                          Expanded(flex: 25, child: Container(color: const Color(0xFF0566D9))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Shop commission retention: 25%', style: TextStyle(color: Color(0xFF869397), fontSize: 10)),
                      Text('Direct Ledger Sync', style: TextStyle(color: Color(0xFF869397), fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. VEHICLE DOCUMENTS
  // ---------------------------------------------------------------------------
  Widget _buildDocumentsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3854).withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.folder_shared_rounded, color: Color(0xFF4CD7F6), size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Vehicle Documents',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1BBD85).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt, color: Color(0xFF4EDEAE), size: 12),
                    SizedBox(width: 2),
                    Text(
                      'Quick AI Scan',
                      style: TextStyle(color: Color(0xFF4EDEAE), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Upload Tile 1: RC Smart Card
          InkWell(
            onTap: _showRcPickerOptions,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF171B27),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_rcImageBytes != null || (_rcExistingUrl != null && _rcExistingUrl!.isNotEmpty))
                      ? const Color(0xFF4EDEAE).withValues(alpha: 0.4)
                      : const Color(0x1AFFFFFF),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF252A36),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: (_rcImageBytes != null)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(_rcImageBytes!, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.contact_emergency_rounded, color: Color(0xFF4CD7F6), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('RC Book / Smart Card', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            CircleAvatar(
                              radius: 3,
                              backgroundColor: (_rcImageBytes != null || (_rcExistingUrl != null && _rcExistingUrl!.isNotEmpty))
                                  ? const Color(0xFF4EDEAE)
                                  : const Color(0xFF869397),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _rcFileName ?? (_rcExistingUrl != null && _rcExistingUrl!.isNotEmpty ? 'RC Document on File' : 'Tap to upload or take photo'),
                          style: TextStyle(
                            color: (_rcImageBytes != null || (_rcExistingUrl != null && _rcExistingUrl!.isNotEmpty))
                                ? const Color(0xFF4EDEAE)
                                : const Color(0xFF869397),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _showRcPickerOptions,
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252A36),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x334CD7F6)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.photo_camera_rounded, color: Color(0xFF4CD7F6), size: 14),
                          SizedBox(width: 4),
                          Text('Retake', style: TextStyle(color: Color(0xFF4CD7F6), fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Upload Tile 2: Comprehensive Insurance
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF171B27),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF252A36),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.verified_rounded, color: Color(0xFFADC6FF), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Comprehensive Insurance', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('Digit General Insurance Ltd.', style: TextStyle(color: Color(0xFF869397), fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Valid', style: TextStyle(color: Color(0xFF4CD7F6), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                const Text('Policy Expiration Date', style: TextStyle(color: Color(0xFFBCC9CD), fontSize: 11)),
                const SizedBox(height: 4),
                TextField(
                  controller: _expiryDateCtrl,
                  readOnly: true,
                  onTap: _selectPolicyExpiryDate,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.event_rounded, color: Color(0xFF4CD7F6), size: 18),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.edit_calendar_rounded, color: Color(0xFF4CD7F6), size: 18),
                      onPressed: _selectPolicyExpiryDate,
                    ),
                    hintText: 'YYYY-MM-DD (Tap to pick date)',
                    hintStyle: const TextStyle(color: Color(0xFF869397), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF252A36),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FLOATING STICKY ACTION DECK
  // ---------------------------------------------------------------------------
  Widget _buildStickyActionDeck(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0E131E).withValues(alpha: 0.98),
          border: const Border(top: BorderSide(color: Color(0x1AFFFFFF), width: 1)),
          boxShadow: const [
            BoxShadow(color: Color(0x99000000), blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        child: Row(
          children: [
            // Save Draft Button
            GestureDetector(
              onTap: _handleSaveDraft,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF252A36),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x334CD7F6)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.save_rounded, color: Color(0xFFADC6FF), size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Save Draft',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

          // Publish to Fleet Button
          Expanded(
            child: GestureDetector(
              onTap: _isLoading ? null : _handlePublish,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF0566D9)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Color(0x5906B6D4), blurRadius: 16, offset: Offset(0, 4)),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF003640)),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isEditing ? Icons.check_circle_rounded : Icons.add_circle_rounded,
                              color: const Color(0xFF003640),
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isEditing ? 'Update Vehicle' : 'Publish to Fleet',
                              style: const TextStyle(
                                color: Color(0xFF003640),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
