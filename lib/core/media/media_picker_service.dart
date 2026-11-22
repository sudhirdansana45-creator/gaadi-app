import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../permissions/permission_service.dart';

class MediaPickerService {
  MediaPickerService._();
  static final MediaPickerService instance = MediaPickerService._();

  final ImagePicker _picker = ImagePicker();

  /// Captures an image with the camera after checking/requesting permission.
  /// Automatically downsizes to max 1600x1600 and compresses at 80% quality
  /// to strip large metadata and optimize upload bandwidth.
  Future<XFile?> captureImageWithCamera({
    required BuildContext context,
    String? title,
    String? rationale,
  }) async {
    final granted = await PermissionService.instance.requestCamera(
      context: context,
      title: title ?? 'Capture Document Photo',
      message: rationale ??
          'Camera access is required to take photos of customer Driving Licences, ID proofs, and vehicle inspection status.',
    );

    if (!granted) {
      // Offer graceful fallback to gallery if camera is not allowed
      if (context.mounted) {
        final fallbackToGallery = await _askFallbackToGallery(context);
        if (fallbackToGallery && context.mounted) {
          return pickImageFromGallery(context: context);
        }
      }
      return null;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );

      return pickedFile;
    } catch (e) {
      debugPrint('[MediaPickerService] Error capturing image: $e');
      return null;
    }
  }

  /// Picks an image from gallery with least-privilege permission checks.
  Future<XFile?> pickImageFromGallery({
    required BuildContext context,
    String? title,
    String? rationale,
  }) async {
    final granted = await PermissionService.instance.requestPhotos(
      context: context,
      title: title ?? 'Select Document from Photos',
      message: rationale ??
          'Choose a saved photo of driving licence, customer proof, or vehicle image.',
    );

    if (!granted) return null;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );

      return pickedFile;
    } catch (e) {
      debugPrint('[MediaPickerService] Error picking from gallery: $e');
      return null;
    }
  }

  /// Picks multiple images from gallery or file system.
  Future<List<XFile>> pickMultipleImagesFromGallery({
    required BuildContext context,
    String? title,
    String? rationale,
  }) async {
    final granted = await PermissionService.instance.requestPhotos(
      context: context,
      title: title ?? 'Select Vehicle Inspection Photos',
      message: rationale ??
          'Choose saved inspection photos from your gallery or files.',
    );

    if (!granted) return [];

    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );

      return pickedFiles;
    } catch (e) {
      debugPrint('[MediaPickerService] Error picking multiple images: $e');
      return [];
    }
  }

  /// In-app fallback prompt if camera is denied
  Future<bool> _askFallbackToGallery(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Camera Unavailable', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: const Text(
              'Camera access was not granted. Would you like to select an existing photo or document from your gallery instead?',
              style: TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Choose from Gallery'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
