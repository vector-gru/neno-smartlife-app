// ─────────────────────────────────────────────────────────────────────────────
// NotificationService
//
// Responsibilities:
//   • Initialise firebase_messaging and flutter_local_notifications once.
//   • Request notification permission from the OS on first launch.
//   • Obtain the FCM registration token for this device.
//   • Show foreground notifications via a local notification channel so that
//     messages are visible even when the app is in the foreground.
//
// FCM delivery path used here:
//   Customer taps "I'm Interested"
//     → writes an `interest_requests` Firestore document
//     → InterestRequestService (running on the admin device) detects the write
//     → calls NotificationService.showInterestNotification()
//
// This avoids needing Cloud Functions or exposing a server key on the client.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// The Android notification channel used for all "interest" alerts.
const _kChannelId = 'neno_interest';
const _kChannelName = 'Customer Interest';
const _kChannelDesc = 'Alerts when a customer expresses interest in a product';

/// Separate channel for store-wide product announcements.
const _kProductChannelId = 'neno_products';
const _kProductChannelName = 'New Products';
const _kProductChannelDesc =
    'Alerts when new or updated products are added to the store';

/// Top-level background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are shown automatically by FCM on Android.
  // No action needed here for data-only messages handled via Firestore.
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  // ── Initialise ─────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    // Register background handler (must be called before any other FCM setup).
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request OS permission (iOS prompts; Android 13+ also needs a prompt).
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialise the local notifications plugin.
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // already requested via FCM above
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Create the Android notification channel.
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _kChannelId,
        _kChannelName,
        description: _kChannelDesc,
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      const productChannel = AndroidNotificationChannel(
        _kProductChannelId,
        _kProductChannelName,
        description: _kProductChannelDesc,
        importance: Importance.defaultImportance,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(productChannel);
    }
  }

  // ── FCM token ──────────────────────────────────────────────────────────────

  /// Returns the FCM registration token for this device, or null if
  /// notifications are not available (e.g. permission denied, simulator).
  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Stream that fires whenever the FCM token is refreshed.
  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;

  // ── Show notification ──────────────────────────────────────────────────────

  /// Displays a high-priority local notification for a new "I'm Interested"
  /// event. Call this from the admin-side Firestore listener.
  Future<void> showInterestNotification({
    required String customerName,
    required String customerPhone,
    required String productName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _kChannelId,
      _kChannelName,
      channelDescription: _kChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      // Use a stable ID derived from timestamp so each event shows separately.
      DateTime.now().millisecondsSinceEpoch ~/ 1000 & 0x7FFFFFFF,
      '👋 New Interest — $productName',
      '$customerName · $customerPhone',
      details,
    );
  }

  /// Displays a high-priority local notification for a new purchase request.
  /// Call this from the admin-side Firestore listener.
  Future<void> showPurchaseRequestNotification({
    required String customerName,
    required String customerPhone,
    required List<String> productNames,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _kChannelId,
      _kChannelName,
      channelDescription: _kChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final preview = productNames.isEmpty
        ? 'New purchase request'
        : productNames.length == 1
            ? productNames.first
            : '${productNames.first} + ${productNames.length - 1} more';

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 & 0x7FFFFFFF,
      '🛒 Purchase Request — $customerName',
      '$preview · $customerPhone',
      details,
    );
  }

  /// Displays a notification when the admin confirms or starts a discussion
  /// on a customer's purchase request.
  Future<void> showOrderStatusNotification({
    required String productName,
    required String status, // 'confirmed' | 'inDiscussion'
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _kChannelId,
      _kChannelName,
      channelDescription: _kChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final isConfirmed = status == 'confirmed';
    final title = isConfirmed
        ? '✅ Request Confirmed — $productName'
        : '💬 In Discussion — $productName';
    final body = isConfirmed
        ? 'Your purchase request has been confirmed!'
        : 'Your request is now in discussion with our team.';

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 & 0x7FFFFFFF,
      title,
      body,
      details,
    );
  }

  /// Displays a notification for a new message from admin in a chat thread.
  Future<void> showChatNotification({
    required String senderName,
    required String productName,
    required String preview,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _kChannelId,
      _kChannelName,
      channelDescription: _kChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 & 0x7FFFFFFF,
      '💬 $senderName — $productName',
      preview.isNotEmpty ? preview : 'New message',
      details,
    );
  }

  /// Displays a notification when a new or updated product is listed in
  /// the store. Delivered on a lower-priority channel so it doesn't
  /// interrupt the user as aggressively as order/chat alerts.
  Future<void> showNewProductNotification({
    required String productName,
    required String category,
    required bool isNew,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _kProductChannelId,
      _kProductChannelName,
      channelDescription: _kProductChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title =
        isNew ? '🆕 New in Store — $productName' : '🔄 Updated — $productName';
    final body = isNew
        ? 'A new $category just landed. Tap to check it out!'
        : 'Details updated on $productName. Take another look!';

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 & 0x7FFFFFFF,
      title,
      body,
      details,
    );
  }
}
