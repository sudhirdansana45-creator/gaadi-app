import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/security/screen_security_service.dart';
import '../theme/app_colors.dart';

class ImageViewerDialog extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String title;

  const ImageViewerDialog({
    super.key,
    this.imageUrl,
    this.imageBytes,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return SecureScreenWrapper(
      isSecure: true,
      child: Dialog(
        backgroundColor: AppColors.surfaceCard,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 460),
                color: Colors.black,
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 3.5,
                  child: Center(
                    child: imageBytes != null
                        ? Image.memory(
                            imageBytes!,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, stack) => _errorWidget(),
                          )
                        : (imageUrl != null && imageUrl!.isNotEmpty
                            ? Image.network(
                                imageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (ctx, err, stack) => _errorWidget(),
                              )
                            : _errorWidget()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorWidget() {
    return Container(
      height: 200,
      color: AppColors.background,
      child: const Center(
        child: Icon(Icons.image_not_supported_rounded, color: AppColors.textMuted, size: 48),
      ),
    );
  }
}
