import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ImageViewerDialog extends StatelessWidget {
  final String imageUrl;
  final String title;

  const ImageViewerDialog({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Container(
                height: 200,
                color: AppColors.background,
                child: const Center(
                  child: Icon(Icons.image_not_supported_rounded, color: AppColors.textMuted, size: 48),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
