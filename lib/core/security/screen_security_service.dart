import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ScreenSecurityService manages screenshot and screen recording blocking (FLAG_SECURE)
/// for sensitive customer driving licence, ID proof, and payment documents.
class ScreenSecurityService {
  static const MethodChannel _channel = MethodChannel('com.gaadimanager.gaadi_manager/screen_security');

  /// Enables screenshot & screen recording blocking.
  static Future<void> enableSecure() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('enableSecure');
      debugPrint('[ScreenSecurityService] FLAG_SECURE enabled for sensitive screen.');
    } catch (e) {
      debugPrint('[ScreenSecurityService] Failed to enable secure screen: $e');
    }
  }

  /// Disables screenshot blocking when exiting sensitive screen.
  static Future<void> disableSecure() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('disableSecure');
      debugPrint('[ScreenSecurityService] FLAG_SECURE disabled.');
    } catch (e) {
      debugPrint('[ScreenSecurityService] Failed to disable secure screen: $e');
    }
  }
}

/// A convenient lifecycle-aware widget that enforces screenshot protection
/// ONLY while the sensitive child widget/screen is active.
class SecureScreenWrapper extends StatefulWidget {
  final Widget child;
  final bool isSecure;

  const SecureScreenWrapper({
    super.key,
    required this.child,
    this.isSecure = true,
  });

  @override
  State<SecureScreenWrapper> createState() => _SecureScreenWrapperState();
}

class _SecureScreenWrapperState extends State<SecureScreenWrapper> {
  @override
  void initState() {
    super.initState();
    if (widget.isSecure) {
      ScreenSecurityService.enableSecure();
    }
  }

  @override
  void didUpdateWidget(covariant SecureScreenWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSecure != widget.isSecure) {
      if (widget.isSecure) {
        ScreenSecurityService.enableSecure();
      } else {
        ScreenSecurityService.disableSecure();
      }
    }
  }

  @override
  void dispose() {
    if (widget.isSecure) {
      ScreenSecurityService.disableSecure();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
