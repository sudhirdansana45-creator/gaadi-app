import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/image_viewer_dialog.dart';

class AppPlaceholders {
  static void showSharePlaceholder(BuildContext context, {String title = 'Share Invoice'}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing "$title" via system share dialog...'),
        backgroundColor: AppColors.infoBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showImagePickerPlaceholder(BuildContext context, {String label = 'Photo Upload'}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label: Camera/Gallery picker connected.'),
        backgroundColor: AppColors.primaryCyan,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showImageViewer(BuildContext context, {required String imageUrl, required String title}) {
    showDialog(
      context: context,
      builder: (ctx) => ImageViewerDialog(imageUrl: imageUrl, title: title),
    );
  }
}
