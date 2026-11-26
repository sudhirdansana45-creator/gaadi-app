import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../theme/app_colors.dart';

class VehicleImageCropperDialog extends StatefulWidget {
  final Uint8List imageBytes;

  const VehicleImageCropperDialog({
    super.key,
    required this.imageBytes,
  });

  static Future<Uint8List?> show(BuildContext context, Uint8List imageBytes) {
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => VehicleImageCropperDialog(imageBytes: imageBytes),
    );
  }

  @override
  State<VehicleImageCropperDialog> createState() => _VehicleImageCropperDialogState();
}

class _VehicleImageCropperDialogState extends State<VehicleImageCropperDialog> {
  final GlobalKey _cropAreaKey = GlobalKey();
  final TransformationController _transController = TransformationController();

  double _aspectRatio = 16 / 9; // 16:9 is ideal for vehicle fleet showcase
  String _aspectRatioLabel = '16:9 (Banner)';
  double _rotationAngle = 0.0;
  bool _isProcessing = false;
  Uint8List? _previewCroppedBytes;

  final List<Map<String, dynamic>> _aspectRatios = [
    {'label': '16:9 (Banner)', 'ratio': 16 / 9},
    {'label': '4:3 (Standard)', 'ratio': 4 / 3},
    {'label': '1:1 (Square)', 'ratio': 1.0},
  ];

  @override
  void dispose() {
    _transController.dispose();
    super.dispose();
  }

  void _rotateClockwise() {
    setState(() {
      _rotationAngle += math.pi / 2;
    });
  }

  void _resetTransform() {
    setState(() {
      _rotationAngle = 0.0;
      _transController.value = Matrix4.identity();
    });
  }

  Future<Uint8List?> _captureCroppedBytes() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final boundary = _cropAreaKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return widget.imageBytes;

      final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List() ?? widget.imageBytes;
    } catch (e) {
      debugPrint('[VehicleImageCropperDialog] Error during capture: $e');
      return widget.imageBytes;
    }
  }

  Future<void> _previewCrop() async {
    setState(() => _isProcessing = true);
    try {
      final bytes = await _captureCroppedBytes();
      if (mounted && bytes != null) {
        setState(() {
          _previewCroppedBytes = bytes;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _adjustAgain() {
    setState(() {
      _previewCroppedBytes = null;
    });
  }

  Future<void> _saveCroppedPhoto() async {
    setState(() => _isProcessing = true);
    try {
      final bytes = _previewCroppedBytes ?? await _captureCroppedBytes();
      if (mounted) {
        Navigator.pop(context, bytes ?? widget.imageBytes);
      }
    } catch (e) {
      debugPrint('[VehicleImageCropperDialog] Error saving cropped image: $e');
      if (mounted) {
        Navigator.pop(context, widget.imageBytes);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = math.min(screenSize.width - 20, 580.0);
    final maxCropHeight = math.min(screenSize.height * 0.38, 280.0);

    return Dialog(
      backgroundColor: const Color(0xFF0E131E),
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0x334CD7F6), width: 1.5),
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxHeight: screenSize.height * 0.88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fixed Header
            _buildHeader(context),
            const Divider(color: Color(0x1AFFFFFF), height: 1),

            // Scrollable / Flexible middle content
            Flexible(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_previewCroppedBytes == null) ...[
                      _buildRatioPills(),
                      _buildInteractiveViewport(maxCropHeight),
                      _buildControlsToolbar(),
                    ] else ...[
                      _buildPreviewViewport(maxCropHeight),
                    ],
                  ],
                ),
              ),
            ),

            const Divider(color: Color(0x1AFFFFFF), height: 1),

            // Pinned Bottom Actions Bar
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.crop_rotate_rounded, color: AppColors.primaryCyan, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _previewCroppedBytes == null ? 'Crop & Adjust Photo' : 'Cropped Photo Preview',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _previewCroppedBytes == null
                      ? 'Pinch or drag to reposition vehicle in frame'
                      : 'Review cropped result, then click Save & Add',
                  style: const TextStyle(
                    color: Color(0xFF869397),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context, null),
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
            tooltip: 'Cancel',
          ),
        ],
      ),
    );
  }

  Widget _buildRatioPills() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            'Ratio:',
            style: TextStyle(color: Color(0xFF869397), fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _aspectRatios.map((item) {
                  final isSelected = _aspectRatioLabel == item['label'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(item['label'] as String),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _aspectRatioLabel = item['label'] as String;
                          _aspectRatio = item['ratio'] as double;
                        });
                      },
                      selectedColor: const Color(0xFF06B6D4),
                      backgroundColor: const Color(0xFF171B27),
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFF003640) : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF06B6D4) : const Color(0x1AFFFFFF),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveViewport(double maxCropHeight) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x3306B6D4)),
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxHeight: maxCropHeight),
          child: AspectRatio(
            aspectRatio: _aspectRatio,
            child: Stack(
              children: [
                // RepaintBoundary capturing the scaled & transformed image
                RepaintBoundary(
                  key: _cropAreaKey,
                  child: ClipRect(
                    child: Container(
                      color: Colors.black,
                      width: double.infinity,
                      height: double.infinity,
                      child: Transform.rotate(
                        angle: _rotationAngle,
                        child: InteractiveViewer(
                          transformationController: _transController,
                          minScale: 0.8,
                          maxScale: 4.5,
                          boundaryMargin: const EdgeInsets.all(80),
                          child: Image.memory(
                            widget.imageBytes,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Transparent Overlay with Grid & Corner Brackets
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0x664CD7F6), width: 1.5),
                    ),
                    child: Stack(
                      children: [
                        // Rule-of-thirds grid
                        Column(
                          children: [
                            const Spacer(),
                            Container(height: 1, color: const Color(0x26FFFFFF)),
                            const Spacer(),
                            Container(height: 1, color: const Color(0x26FFFFFF)),
                            const Spacer(),
                          ],
                        ),
                        Row(
                          children: [
                            const Spacer(),
                            Container(width: 1, color: const Color(0x26FFFFFF)),
                            const Spacer(),
                            Container(width: 1, color: const Color(0x26FFFFFF)),
                            const Spacer(),
                          ],
                        ),
                        // Corner markers
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Color(0xFF4CD7F6), width: 2.5),
                                left: BorderSide(color: Color(0xFF4CD7F6), width: 2.5),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Color(0xFF4CD7F6), width: 2.5),
                                right: BorderSide(color: Color(0xFF4CD7F6), width: 2.5),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xFF4CD7F6), width: 2.5),
                                left: BorderSide(color: Color(0xFF4CD7F6), width: 2.5),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xFF4CD7F6), width: 2.5),
                                right: BorderSide(color: Color(0xFF4CD7F6), width: 2.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlsToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Adjustment buttons row: Rotate, Reset, Preview
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: Color(0x33FFFFFF)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _rotateClockwise,
                  icon: const Icon(Icons.rotate_right_rounded, size: 16, color: Color(0xFF4CD7F6)),
                  label: const Text('Rotate 90°', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: Color(0x33FFFFFF)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _resetTransform,
                  icon: const Icon(Icons.restart_alt_rounded, size: 16, color: Color(0xFF869397)),
                  label: const Text('Reset', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4EDEAE),
                    side: const BorderSide(color: Color(0x334EDEAE)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isProcessing ? null : _previewCrop,
                  icon: const Icon(Icons.remove_red_eye_rounded, size: 16, color: Color(0xFF4EDEAE)),
                  label: const Text('Preview', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewViewport(double maxCropHeight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4EDEAE).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x334EDEAE)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF4EDEAE)),
                SizedBox(width: 6),
                Text(
                  'Crop Ready! Tap "Save & Add Photo" below',
                  style: TextStyle(color: Color(0xFF4EDEAE), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            constraints: BoxConstraints(maxHeight: maxCropHeight),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF06B6D4), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.memory(
                _previewCroppedBytes!,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4CD7F6),
                    side: const BorderSide(color: Color(0x334CD7F6)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isProcessing ? null : _adjustAgain,
                  icon: const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF4CD7F6)),
                  label: const Text(
                    'Re-adjust Crop',
                    style: TextStyle(color: Color(0xFF4CD7F6), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    foregroundColor: const Color(0xFF003640),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isProcessing ? null : _saveCroppedPhoto,
                  icon: const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF003640)),
                  label: const Text(
                    'Save & Add Photo',
                    style: TextStyle(color: Color(0xFF003640), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final bool isPreview = _previewCroppedBytes != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      color: const Color(0xFF0B101B),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary full-width Crop/Save button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
                foregroundColor: const Color(0xFF003640),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 4,
              ),
              onPressed: _isProcessing ? null : _saveCroppedPhoto,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF003640)),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF003640)),
              label: Text(
                _isProcessing
                    ? 'Saving...'
                    : (isPreview ? 'Save & Add Photo' : 'Crop & Add Photo'),
                style: const TextStyle(
                  color: Color(0xFF003640),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Secondary actions: Keep Original & Cancel/Adjust
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () => Navigator.pop(context, widget.imageBytes), // Keep original without crop
                icon: const Icon(Icons.image_outlined, size: 15, color: Color(0xFF94A3B8)),
                label: const Text(
                  'Use Original (No Crop)',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              if (isPreview)
                TextButton.icon(
                  onPressed: _isProcessing ? null : _adjustAgain,
                  icon: const Icon(Icons.tune_rounded, size: 15, color: Color(0xFF4CD7F6)),
                  label: const Text(
                    'Re-adjust',
                    style: TextStyle(color: Color(0xFF4CD7F6), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                )
              else
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
