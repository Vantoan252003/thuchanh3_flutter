import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Handler cho thông báo nền - PHẢI ở top-level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Xử lý thông báo nền: ${message.messageId}');
  debugPrint('📨 Title: ${message.notification?.title}');
  debugPrint('📝 Body: ${message.notification?.body}');
}

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FCMService _instance = FCMService._internal();

  factory FCMService() {
    return _instance;
  }

  FCMService._internal();

  Future<void> initialize() async {
    debugPrint('🚀 Đang khởi tạo FCM Service...');

    // Khởi tạo Local Notifications
    await _initializeLocalNotifications();

    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('✅ Trạng thái quyền: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Người dùng đã cấp quyền thông báo');

      // Lấy và in ra FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('');
        debugPrint('==============================================');
        debugPrint('🔑 FCM TOKEN (Copy để test thông báo):');
        debugPrint(token);
        debugPrint('==============================================');
        debugPrint('');

        // Lắng nghe khi token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          debugPrint('🔄 FCM Token đã refresh: $newToken');
        });
      } else {
        debugPrint('❌ Không lấy được FCM token');
      }
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('⚠️ Quyền thông báo tạm thời');
    } else {
      debugPrint('❌ Người dùng từ chối quyền thông báo');
    }

    // Xử lý thông báo foreground (khi app đang mở)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('');
      debugPrint('📬 ===== NHẬN THÔNG BÁO FOREGROUND =====');
      debugPrint('📨 Title: ${message.notification?.title}');
      debugPrint('📝 Body: ${message.notification?.body}');
      debugPrint('📦 Data: ${message.data}');
      debugPrint('🆔 Message ID: ${message.messageId}');
      debugPrint('=======================================');
      debugPrint('');

      // Hiển thị notification ngay cả khi app đang mở
      _showLocalNotification(message);
    });

    // Xử lý khi nhấn vào thông báo (khi app đang ở background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('');
      debugPrint('👆 ===== THÔNG BÁO ĐƯỢC MỞ =====');
      debugPrint('📨 Title: ${message.notification?.title}');
      debugPrint('📝 Body: ${message.notification?.body}');
      debugPrint('📦 Data: ${message.data}');
      debugPrint('==================================');
      debugPrint('');
    });

    // Kiểm tra xem app có được mở từ notification không
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('');
      debugPrint('🚀 ===== APP MỞ TỪ THÔNG BÁO =====');
      debugPrint('📨 Title: ${initialMessage.notification?.title}');
      debugPrint('📝 Body: ${initialMessage.notification?.body}');
      debugPrint('===================================');
      debugPrint('');
    }

    debugPrint('✅ FCM Service đã khởi tạo thành công!');
  }

  // Khởi tạo Local Notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('📱 Người dùng nhấn vào notification: ${response.payload}');
      },
    );

    debugPrint('✅ Local Notifications đã khởi tạo');
  }

  // Hiển thị local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel', // Channel ID
      'High Importance Notifications', // Channel name
      channelDescription: 'This channel is used for important notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Thông báo mới',
      message.notification?.body ?? '',
      notificationDetails,
      payload: message.data.toString(),
    );

    debugPrint('🔔 Đã hiển thị local notification');
  }

  // Hàm để lấy token bất cứ lúc nào
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // Hàm để subscribe topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('✅ Đã subscribe topic: $topic');
  }

  // Hàm để unsubscribe topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('✅ Đã unsubscribe topic: $topic');
  }
}
