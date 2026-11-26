import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'platform_util.dart';

/// Helper class for launching external apps, UPI payments, WhatsApp,
/// phone calls, SMS, and sharing/opening PDF reports safely.
class ExternalActions {
  /// Opens a WhatsApp chat with pre-filled message.
  /// Formats phone to international E.164 (defaults to Indian +91 if 10 digits).
  static Future<bool> openWhatsApp({
    required String phone,
    String? message,
    BuildContext? context,
  }) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.startsWith('+')) {
      cleanPhone = cleanPhone.substring(1);
    } else if (cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }

    final encodedMsg = message != null ? Uri.encodeComponent(message) : '';
    final primaryUri = Uri.parse('whatsapp://send?phone=$cleanPhone${encodedMsg.isNotEmpty ? '&text=$encodedMsg' : ''}');
    final fallbackUri = Uri.parse('https://wa.me/$cleanPhone${encodedMsg.isNotEmpty ? '?text=$encodedMsg' : ''}');

    try {
      if (await canLaunchUrl(primaryUri)) {
        return await launchUrl(primaryUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(fallbackUri)) {
        return await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      } else {
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp is not installed on this device.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('[ExternalActions] Error opening WhatsApp: $e');
      return false;
    }
  }

  /// Initiates a phone call using the system dialer.
  static Future<bool> makePhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }

  /// Opens the default SMS application with an optional draft message.
  static Future<bool> sendSMS({required String phone, String? body}) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: body != null ? {'body': body} : null,
    );
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }

  /// Launches Indian UPI payment application (Google Pay, PhonePe, Paytm, BHIM)
  /// for plan purchases or rental payment collection.
  static Future<bool> launchUpiPayment({
    required String vpa,
    required String payeeName,
    required double amount,
    required String transactionNote,
    String currency = 'INR',
    BuildContext? context,
  }) async {
    final uri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': vpa,
        'pn': payeeName,
        'am': amount.toStringAsFixed(2),
        'cu': currency,
        'tn': transactionNote,
      },
    );

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No supported UPI payment app (GPay, PhonePe, Paytm) found.'),
              backgroundColor: Colors.amber,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('[ExternalActions] Error launching UPI: $e');
      return false;
    }
  }

  /// Redirects the user to the Google Play Store or Apple App Store for updates.
  static Future<bool> openAppStore({
    String androidPackageName = 'com.gaadimanager.gaadi_manager',
    String? iosAppId,
  }) async {
    final Uri storeUri;
    if (AppPlatform.isAndroid) {
      final marketUri = Uri.parse('market://details?id=$androidPackageName');
      if (await canLaunchUrl(marketUri)) {
        return await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      }
      storeUri = Uri.parse('https://play.google.com/store/apps/details?id=$androidPackageName');
    } else if (AppPlatform.isIOS) {
      storeUri = Uri.parse('https://apps.apple.com/app/id${iosAppId ?? "123456789"}');
    } else {
      storeUri = Uri.parse('https://play.google.com/store/apps/details?id=$androidPackageName');
    }

    if (await canLaunchUrl(storeUri)) {
      return await launchUrl(storeUri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Shares a generated PDF invoice or report using system share sheet.
  static Future<ShareResult> shareFile({
    required String filePath,
    String? subject,
    String? text,
  }) async {
    final file = XFile(filePath);
    return await SharePlus.instance.share(
      ShareParams(
        files: [file],
        subject: subject,
        text: text,
      ),
    );
  }

  /// Shares Gaadi Manager APK / download link with invitation text
  static Future<ShareResult> shareApk({String? downloadUrl, String? customMessage}) async {
    final url = downloadUrl ?? 'https://gaadi.ersudhir.cloud/download/gaadi-manager.apk';
    final text = customMessage ??
        '🚗 *Gaadi Manager - Vehicle Rental & Fleet ERP App*\n\n'
        'Manage fleet inventory, fast rental agreements, instant WhatsApp bills, customer KYC, and partner settlements in one place!\n\n'
        '📥 Download & Install APK:\n$url\n\n'
        'Fast & Secure ERP for vehicle rental businesses across India.';

    return await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Gaadi Manager App APK Download',
      ),
    );
  }

  /// Opens a PDF or document with the device's default viewer.
  static Future<OpenResult> openDocument(String filePath) async {
    return await OpenFilex.open(filePath);
  }
}
