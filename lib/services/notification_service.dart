import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';

/// FCM background message handler (must be top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('FCM [background]: ${message.notification?.title}');
  }
}

/// SafeBuy Nepal — Push Notification Service
/// Wraps Firebase Messaging with FCM token persistence and message handlers.
class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static String? _cachedToken;

  /// Initialise FCM, request permission, register handlers.
  /// Call from main.dart AFTER Firebase.initializeApp.
  static Future<void> initialize() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (kDebugMode) debugPrint('FCM permission denied by user');
        return;
      }

      // Get and cache token
      _cachedToken = await _fcm.getToken();
      if (kDebugMode) debugPrint('FCM token: $_cachedToken');

      // Listen for token refreshes
      _fcm.onTokenRefresh.listen((token) {
        _cachedToken = token;
        if (kDebugMode) debugPrint('FCM token refreshed');
      });

      // Background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          debugPrint(
              'FCM [foreground]: ${message.notification?.title} - ${message.notification?.body}');
        }
      });

      // Message opened (from terminated/background to foreground)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          debugPrint('FCM [opened]: ${message.data}');
        }
      });
    } catch (e) {
      if (kDebugMode) debugPrint('FCM initialize error: $e');
    }
  }

  /// Returns the current FCM token (cached if available).
  static Future<String?> getToken() async {
    _cachedToken ??= await _fcm.getToken();
    return _cachedToken;
  }

  /// Save the user's FCM token to their Firestore user document.
  static Future<void> saveTokenToFirestore(String userId) async {
    try {
      final token = await getToken();
      if (token == null) return;
      await FirebaseFirestore.instance
          .collection(AppConstants.colUsers)
          .doc(userId)
          .set({'fcmToken': token}, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('saveTokenToFirestore error: $e');
    }
  }

  /// Remove the FCM token from Firestore (called on logout/account deletion).
  static Future<void> removeTokenFromFirestore(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.colUsers)
          .doc(userId)
          .update({'fcmToken': FieldValue.delete()});
    } catch (e) {
      if (kDebugMode) debugPrint('removeTokenFromFirestore error: $e');
    }
  }
}
