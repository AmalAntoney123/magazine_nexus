import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'theme/app_theme.dart';
import 'pages/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'pages/settings_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'pages/admin/admin_panel_page.dart';
import 'pages/profile_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Add this function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await NotificationService.initialize();

    // Initialize Firebase Cloud Messaging
    final fcm = FirebaseMessaging.instance;

    // Get FCM token
    String? token = await fcm.getToken();
    print('FCM Token: $token');

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });

    // Check for expiring subscriptions
    await NotificationService.checkExpiringSubscriptions();

    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _isUserAdmin(String uid) async {
    final snapshot = await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(uid)
        .child('role')
        .get();
    return snapshot.exists && snapshot.value == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Magazine Nexus',
      theme: AppTheme.lightTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            return FutureBuilder<bool>(
              future: _isUserAdmin(snapshot.data!.uid),
              builder: (context, adminSnapshot) {
                if (adminSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (adminSnapshot.data == true) {
                  return const AdminPanelPage(); // User is admin
                }

                return HomePage(); // Regular user
              },
            );
          }

          return const MyHomePage(title: 'Magazine Nexus');
        },
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '/settings': (context) => SettingsPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => HomePage(),
        '/admin': (context) => const AdminPanelPage(),
        '/profile': (context) => ProfilePage(),
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 250,
                height: 250,
              ),
              const SizedBox(height: 24),
              Text(
                'A user-friendly platform that simplifies magazine subscription management with automated renewals, reminders, and personalized recommendations.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

    final subscriptionsSnapshot = await FirebaseDatabase.instance
        .ref()
        .child('subscriptions')
        .child(user.uid)
        .get();

    if (!subscriptionsSnapshot.exists) return;

    final subscriptions = Map<String, dynamic>.from(
        subscriptionsSnapshot.value as Map<dynamic, dynamic>);

    final now = DateTime.now();
    final warningThreshold = Duration(days: 7); // Notify 7 days before expiry

    for (var subscription in subscriptions.entries) {
      final endDate = DateTime.parse(subscription.value['endDate']);
      final timeUntilExpiry = endDate.difference(now);

      if (timeUntilExpiry.isNegative) continue; // Skip expired subscriptions

      if (timeUntilExpiry <= warningThreshold) {
        final daysLeft = timeUntilExpiry.inDays;
        await _showExpiryNotification(
          subscription.value['magazineTitle'],
          daysLeft,
        );
      }
    }
  }

  static Future<void> _showExpiryNotification(
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
}
