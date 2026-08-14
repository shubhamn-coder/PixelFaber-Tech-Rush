import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ChatNotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime timestamp;
  bool isRead;

  ChatNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  static final List<ChatNotificationItem> liveNotifications = [];

  bool get hasUnread => liveNotifications.any((n) => !n.isRead);

  void markAllRead() {
    for (var n in liveNotifications) {
      n.isRead = true;
    }
  }

  void addChatNotification({required String title, required String body}) {
    final item = ChatNotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: 'CHAT',
      timestamp: DateTime.now(),
      isRead: false,
    );
    liveNotifications.insert(0, item);
    showNotification(
      id: liveNotifications.length,
      title: title,
      body: body,
    );
  }

  Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(initializationSettings);
    _initialized = true;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      if (!_initialized) await init();

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'greendrop_channel_id',
        'GreenDrop Notifications',
        channelDescription: 'Notifications for GreenDrop donations and relief',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Native notification trigger: $title - $body ($e)');
    }
  }
}
