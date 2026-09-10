import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  void Function(String location)? _onOpen;
  String? _pendingLocation;

  static const AndroidNotificationChannel _emergencyChannel = AndroidNotificationChannel(
    'emergency_alerts',
    'Emergency Alerts',
    description: 'Критичні сповіщення та збори за тривогою.',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel _updatesChannel = AndroidNotificationChannel(
    'hub_updates',
    'Hub Updates',
    description: 'Новини та опитування DSNS Hub.',
    importance: Importance.defaultImportance,
  );

  set onOpen(void Function(String location)? callback) {
    _onOpen = callback;
    final pending = _pendingLocation;
    if (callback != null && pending != null) {
      _pendingLocation = null;
      callback(pending);
    }
  }

  static String? locationForData(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    switch (type) {
      case 'EMERGENCY':
        final id = data['broadcastId']?.toString();
        if (id == null || id.isEmpty) return null;
        return '/profile/alerts/$id';
      case 'NEWS':
        final id = data['newsId']?.toString();
        if (id == null || id.isEmpty) return null;
        return '/news/$id';
      case 'POLL':
        final id = data['pollId']?.toString();
        if (id == null || id.isEmpty) return null;
        return '/polls/$id';
      default:
        return null;
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_emergencyChannel);
    await androidPlugin?.createNotificationChannel(_updatesChannel);

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        _openFromPayload(response.payload);
      },
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_openFromRemote);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _openFromRemote(initial);
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final RemoteNotification? notification = message.notification;
    if (notification == null) return;

    final isEmergency = message.data['type'] == 'EMERGENCY';
    final channel = isEmergency ? _emergencyChannel : _updatesChannel;

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: '@mipmap/ic_launcher',
          importance: isEmergency ? Importance.high : Importance.defaultImportance,
          priority: isEmergency ? Priority.high : Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _openFromRemote(RemoteMessage message) {
    _navigate(locationForData(message.data));
  }

  void _openFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        _navigate(locationForData(decoded));
      } else if (decoded is Map) {
        _navigate(locationForData(decoded.cast<String, dynamic>()));
      }
    } catch (_) {
      // Ignore malformed local payloads.
    }
  }

  void _navigate(String? location) {
    if (location == null || location.isEmpty) return;
    final callback = _onOpen;
    if (callback != null) {
      callback(location);
    } else {
      _pendingLocation = location;
    }
  }

  Future<void> requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );
  }

  Future<String?> getToken() async {
    final token = await _messaging.getToken();
    if (kDebugMode) {
      debugPrint('FCM token registered');
    }
    return token;
  }

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}
