import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:amarnath_enterprise_client_app/core/constants/database_paths.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background FCM message: ${message.messageId}');
}

/// Centralized notification service managing Firebase Cloud Messaging (FCM),
/// local notification channels, and Client FCM device token lifecycle.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  /// Global navigator key configured on MaterialApp to enable notification deep linking.
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  bool get _isFirebaseAvailable => Firebase.apps.isNotEmpty;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseDatabase get _database => FirebaseDatabase.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'amarnath_client_notifications',
    'Amarnath Enterprise Client Notifications',
    description: 'Account approval, product updates, and order status notifications',
    importance: Importance.max,
  );

  bool _initialized = false;
  String? _registeredToken;

  /// Initializes local notifications, channels, and FCM message listeners.
  Future<void> initialize() async {
    if (_initialized || !_isFirebaseAvailable || kIsWeb) return;

    try {
      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(_channel);

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('FCM Notification permission: ${settings.authorizationStatus}');

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService initialization skipped or failed: $e');
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
  }

  /// Registers the current device's FCM token under the approved Client's database record:
  /// `amarntath_enterprise/users/{uid}/fcmTokens/{encodedToken}`.
  ///
  /// Strictly verifies that `role == 'client'` and `status == 'approved'`.
  Future<void> registerCurrentClientToken() async {
    if (!_isFirebaseAvailable) return;

    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('Cannot register FCM client token: no signed-in user.');
      return;
    }

    try {
      final userSnapshot = await _database
          .ref(DatabasePaths.user(user.uid))
          .get()
          .timeout(const Duration(seconds: 4));

      if (!userSnapshot.exists ||
          userSnapshot.value == null ||
          userSnapshot.value is! Map) {
        debugPrint('Cannot register FCM client token: user record missing.');
        return;
      }

      final userData = userSnapshot.value as Map<dynamic, dynamic>;
      final role = userData['role']?.toString().trim().toLowerCase();
      final status = userData['status']?.toString().trim().toLowerCase();

      // Only register for approved clients: reject owner, pending, rejected
      if (role != 'client' || status != 'approved') {
        debugPrint(
          'Cannot register FCM client token: user is not an approved client (role: $role, status: $status).',
        );
        return;
      }

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FCM did not return a device token for client.');
        return;
      }

      await _saveTokenForCurrentUser(token);
    } catch (e) {
      debugPrint('FCM client token registration failed: $e');
    }
  }

  /// Removes the current device's FCM token from the authenticated Client's user record before logout.
  Future<void> unregisterCurrentClientToken() async {
    if (!_isFirebaseAvailable) return;
    await _removeTokenForCurrentUser();
  }

  String _encodeTokenKey(String token) {
    return base64Url.encode(utf8.encode(token));
  }

  Future<void> _saveTokenForCurrentUser(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final tokenKey = _encodeTokenKey(token);

      final tokenRef = _database
          .ref(DatabasePaths.user(user.uid))
          .child('fcmTokens')
          .child(tokenKey);

      await tokenRef.set({
        'token': token,
        'platform': defaultTargetPlatform.name,
        'updatedAt': ServerValue.timestamp,
      });

      _registeredToken = token;
      debugPrint('FCM token registered for Client ${user.uid}.');
    } catch (e) {
      debugPrint('Unable to save FCM token to Realtime Database: $e');
    }
  }

  Future<void> _removeTokenForCurrentUser() async {
    final user = _auth.currentUser;
    final token = _registeredToken ??
        (_isFirebaseAvailable ? await _messaging.getToken() : null);

    if (user == null || token == null || token.isEmpty) return;

    try {
      final tokenKey = _encodeTokenKey(token);

      await _database
          .ref(DatabasePaths.user(user.uid))
          .child('fcmTokens')
          .child(tokenKey)
          .remove();

      _registeredToken = null;
      debugPrint('FCM token removed for Client.');
    } catch (e) {
      debugPrint('Unable to remove FCM token from Realtime Database: $e');
    }
  }
}
