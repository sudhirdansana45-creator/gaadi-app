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

  Future<void> _applyCrop() async {
    setState(() => _isProcessing = true);
    try {
      // Small delay to allow any pending UI renders
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary = _cropAreaKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) Navigator.pop(context, widget.imageBytes);
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();

      if (mounted) {
        Navigator.pop(context, bytes ?? widget.imageBytes);
      }
    } catch (e) {
      debugPrint('[VehicleImageCropperDialog] Error during crop: $e');
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
    final dialogWidth = math.min(screenSize.width - 32, 600.0);
    final maxCropHeight = math.min(screenSize.height * 0.5, 380.0);

    return Dialog(
      backgroundColor: const Color(0xFF0E131E),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0x334CD7F6), width: 1),
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxHeight: screenSize.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crop & Adjust Photo',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pinch or drag to reposition vehicle in frame',
                          style: TextStyle(
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
            ),

            const Divider(color: Color(0x1AFFFFFF), height: 1),

            // Aspect Ratio Selector Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            ),

            // Interactive Cropping Viewport
            Flexible(
              child: Container(
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

                          // Transparent Overlay with Grid & Corner Brackets (for guidance, not rendered into crop)
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
              ),
            ),

            // Controls Toolbar (Rotate, Reset)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: Color(0x33FFFFFF)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _rotateClockwise,
                    icon: const Icon(Icons.rotate_right_rounded, size: 16, color: Color(0xFF4CD7F6)),
                    label: const Text('Rotate 90°', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: Color(0x33FFFFFF)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _resetTransform,
                    icon: const Icon(Icons.restart_alt_rounded, size: 16, color: Color(0xFF869397)),
                    label: const Text('Reset', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0x1AFFFFFF), height: 1),

            // Bottom Actions (Skip, Apply Crop)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _isProcessing
                        ? null
                        : () => Navigator.pop(context, widget.imageBytes), // Keep original without crop
                    child: const Text(
                      'Use Original',
                      style: TextStyle(color: Color(0xFF869397), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06B6D4),
                      foregroundColor: const Color(0xFF003640),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 4,
                    ),
                    onPressed: _isProcessing ? null : _applyCrop,
                    child: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF003640)),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded, size: 18, color: Color(0xFF003640)),
                              SizedBox(width: 6),
                              Text(
                                'Apply Crop',
                                style: TextStyle(
                                  color: Color(0xFF003640),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
