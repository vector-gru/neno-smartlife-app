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
}
