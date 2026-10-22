import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InAppNotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String category; // 'spray_window', 'weather', 'resistance', 'reminder'
  bool isRead;

  InAppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.category,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'category': category,
        'isRead': isRead,
      };

  factory InAppNotificationItem.fromJson(Map<String, dynamic> json) =>
      InAppNotificationItem(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        category: json['category'] as String? ?? 'reminder',
        isRead: json['isRead'] as bool? ?? false,
      );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  static const String _prefsKey = 'weedguard_notifications_history';
  static const String _channelId = 'weedguard_agronomy_alerts';
  static const String _channelName = 'WeedGuard Field & Spray Alerts';
  static const String _channelDesc =
      'Real-time alerts for weather spray windows, weed resistance and scan follow-ups';

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          // Handle tap
        },
      );

      // Create Android Notification Channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      _isInitialized = true;

      // Seed initial agronomy notifications if first run
      await _seedDefaultNotificationsIfEmpty();
      await updateUnreadCount();
    } catch (e) {
      debugPrint('Notification initialization error: $e');
    }
  }

  static Future<bool> requestPermission() async {
    try {
      if (await Permission.notification.isGranted) {
        return true;
      }
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String category = 'reminder',
    String? payload,
  }) async {
    await initialize();
    await requestPermission();

    final int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Show system notification error: $e');
    }

    // Save to in-app notification center
    await addInAppNotification(
      InAppNotificationItem(
        id: id.toString(),
        title: title,
        body: body,
        timestamp: DateTime.now(),
        category: category,
      ),
    );
  }

  static Future<List<InAppNotificationItem>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefsKey) ?? [];
      return list
          .map((item) =>
              InAppNotificationItem.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addInAppNotification(InAppNotificationItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefsKey) ?? [];
      list.insert(0, jsonEncode(item.toJson()));
      // Keep up to 50 notifications
      if (list.length > 50) {
        list.removeRange(50, list.length);
      }
      await prefs.setStringList(_prefsKey, list);
      await updateUnreadCount();
    } catch (_) {}
  }

  static Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await getNotifications();
      for (final n in list) {
        n.isRead = true;
      }
      final encoded = list.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList(_prefsKey, encoded);
      unreadCountNotifier.value = 0;
    } catch (_) {}
  }

  static Future<void> updateUnreadCount() async {
    try {
      final list = await getNotifications();
      final unread = list.where((n) => !n.isRead).length;
      unreadCountNotifier.value = unread;
    } catch (_) {}
  }

  static Future<void> _seedDefaultNotificationsIfEmpty() async {
    final list = await getNotifications();
    if (list.isEmpty) {
      final initialNotifications = [
        InAppNotificationItem(
          id: '1',
          title: '🌦️ Optimal Spray Window Active',
          body:
              'Wind speed is 5 km/h and rain probability is low. Ideal window for herbicide spray is open until 6:30 PM.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          category: 'spray_window',
        ),
        InAppNotificationItem(
          id: '2',
          title: '🌿 7-Day Follow-up Rescan Due',
          body:
              'Time to check weed mortality rate for North Field after herbicide application.',
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          category: 'reminder',
        ),
        InAppNotificationItem(
          id: '3',
          title: '⚠️ Weather Warning: High Wind Forecast',
          body:
              'Wind speeds may exceed 18 km/h tomorrow morning. Do not spray to prevent drift onto adjacent crops.',
          timestamp: DateTime.now().subtract(const Duration(hours: 12)),
          category: 'weather',
        ),
      ];

      final prefs = await SharedPreferences.getInstance();
      final encoded =
          initialNotifications.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList(_prefsKey, encoded);
    }
  }
}
