import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../services/api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[NotificationService] Background message received: ${message.messageId}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Channel IDs
  static const String channelPlanBilling = 'plan_billing';
  static const String channelBookingReminders = 'booking_reminders';
  static const String channelAnnouncements = 'announcements';

  // Navigation callback when notification is tapped
  Function(String route)? onNotificationNavigation;

  /// Initializes local notifications and Android notification channels.
  /// Also safely attaches FCM listeners if Firebase is configured.
  Future<void> initialize({Function(String route)? onNavigate}) async {
    if (_isInitialized) return;
    onNotificationNavigation = onNavigate;

    // 1. Initialize local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _handlePayloadNavigation(payload);
        }
      },
    );

    // 2. Create the 3 required Android Notification Channels
    if (Platform.isAndroid) {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // High priority: Plan & Billing (expiry reminders 7/3/1 days, payment failure)
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            channelPlanBilling,
            'Plan & Billing',
            description: 'Critical reminders for plan expiry and billing status',
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          ),
        );

        // Default priority: Booking Reminders (pickup, drop, vehicle return)
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            channelBookingReminders,
            'Booking Reminders',
            description: 'Rental pickup, drop-off, and customer handover alerts',
            importance: Importance.defaultImportance,
            enableVibration: true,
            playSound: true,
          ),
        );

        // Low priority: Announcements (app updates & general info)
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            channelAnnouncements,
            'Announcements',
            description: 'System announcements and updates',
            importance: Importance.low,
            enableVibration: false,
            playSound: false,
          ),
        );
      }
    }

    // 3. Safely initialize Firebase Cloud Messaging if Firebase apps exist
    await _setupFirebaseMessaging();

    _isInitialized = true;
    debugPrint('[NotificationService] Initialized successfully with 3 channels.');
  }

  Future<void> _setupFirebaseMessaging() async {
    try {
      // Check if Firebase has been initialized
      if (Firebase.apps.isEmpty) {
        debugPrint('[NotificationService] Firebase not initialized yet (google-services.json pending). Skipping FCM setup.');
        return;
      }

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[NotificationService] Foreground FCM message: ${message.notification?.title}');
        _showForegroundLocalNotification(message);
      });

      // App opened from background notification tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[NotificationService] FCM Notification clicked from background');
        final route = message.data['route'] ?? _mapCategoryToRoute(message.data['category']);
        if (route != null) {
          _handlePayloadNavigation(route);
        }
      });

      // App opened from terminated state
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        final route = initialMessage.data['route'] ?? _mapCategoryToRoute(initialMessage.data['category']);
        if (route != null) {
          _handlePayloadNavigation(route);
        }
      }

      // Sync device token
      await syncDeviceToken();
    } catch (e) {
      debugPrint('[NotificationService] Safe FCM init warning: $e');
    }
  }

  /// Displays foreground notification in system notification tray
  Future<void> _showForegroundLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final category = message.data['category'] ?? '';
    final channelId = _resolveChannelId(category);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _channelTitle(channelId),
      importance: channelId == channelPlanBilling ? Importance.high : Importance.defaultImportance,
      priority: channelId == channelPlanBilling ? Priority.high : Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final route = message.data['route'] ?? _mapCategoryToRoute(category);

    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: route,
    );
  }

  /// Retrieves FCM token and registers it with the Laravel backend.
  Future<void> syncDeviceToken() async {
    try {
      if (Firebase.apps.isEmpty) return;
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        final platform = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');
        await ApiService().updateDeviceToken(token, platform);
        debugPrint('[NotificationService] Synced FCM token with backend: ${token.substring(0, 10)}...');
      }
    } catch (e) {
      debugPrint('[NotificationService] Could not sync FCM token: $e');
    }
  }

  String _resolveChannelId(String category) {
    switch (category.toLowerCase()) {
      case 'plan':
      case 'billing':
      case 'payment':
        return channelPlanBilling;
      case 'announcement':
      case 'update':
        return channelAnnouncements;
      default:
        return channelBookingReminders;
    }
  }

  String _channelTitle(String channelId) {
    switch (channelId) {
      case channelPlanBilling:
        return 'Plan & Billing';
      case channelAnnouncements:
        return 'Announcements';
      default:
        return 'Booking Reminders';
    }
  }

  String? _mapCategoryToRoute(String? category) {
    if (category == null) return null;
    switch (category.toLowerCase()) {
      case 'plan':
      case 'billing':
      case 'payment':
        return '/billing';
      case 'announcement':
      case 'update':
        return '/dashboard';
      case 'booking':
      default:
        return '/bookings';
    }
  }

  void _handlePayloadNavigation(String route) {
    if (onNotificationNavigation != null) {
      onNotificationNavigation!(route);
    }
  }
}
