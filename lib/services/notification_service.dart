import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(settings);
  }

  static Future<void> checkExpiringSubscriptions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final subscriptionsRef = FirebaseDatabase.instance
          .ref()
          .child('subscriptions')
          .child(user.uid);

      final snapshot = await subscriptionsRef.get();
      if (!snapshot.exists) return;

      final subscriptions =
          Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);

      final now = DateTime.now();
      final warningThreshold = Duration(days: 7); // Notify 7 days before expiry

      subscriptions.forEach((key, value) {
        try {
          final endDate = DateTime.parse(value['endDate']);
          final timeUntilExpiry = endDate.difference(now);
          final magazineTitle = value['magazineTitle'] as String;

          if (!timeUntilExpiry.isNegative &&
              timeUntilExpiry <= warningThreshold) {
            final daysLeft = timeUntilExpiry.inDays;
            showExpiryNotification(magazineTitle, daysLeft);
          }
        } catch (e) {
          print('Error processing subscription $key: $e');
        }
      });
    } catch (e) {
      print('Error checking subscriptions: $e');
    }
  }

  static Future<void> showExpiryNotification(
      String magazineTitle, int daysLeft) async {
    const androidDetails = AndroidNotificationDetails(
      'subscription_expiry',
      'Subscription Expiry',
      channelDescription: 'Notifications for expiring subscriptions',
      importance: Importance.high,
      priority: Priority.high,
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

    await _notifications.show(
      DateTime.now().millisecond, // Unique ID
      'Subscription Expiring Soon',
      'Your subscription to $magazineTitle will expire in $daysLeft days',
      details,
    );
  }

  static Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_notification',
      'Test Notifications',
      channelDescription: 'Test notification channel',
      importance: Importance.high,
      priority: Priority.high,
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

    await _notifications.show(
      DateTime.now().millisecond, // Unique ID
      'Test Notification',
      'This is a test notification - App opened at ${DateTime.now().toString()}',
      details,
    );
  }
}
