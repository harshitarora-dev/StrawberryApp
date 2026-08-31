import 'dart:convert';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

// Top level background handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // FCM automatically handles showing notification on system tray for background/terminated app
  // when the message contains a notification object.
  print("Handling background message: ${message.messageId}");
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Request notification permissions
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // 2. Initialize Flutter Local Notifications for showing notifications in the foreground
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/logo');

    // Note: ios/darwin initialization settings can be added here if iOS setup is needed.
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle foreground notification click event here if needed
        print("Notification clicked: ${response.payload}");
      },
    );

    // Create high importance Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notice alerts.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // 3. Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Received foreground message: ${message.notification?.title}");

      final RemoteNotification? notification = message.notification;
      final AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@drawable/logo',
              color: const Color(0xFFE94464),
              colorized: false,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // 4. Update the token periodically when refreshed
    _fcm.onTokenRefresh.listen((token) {
      _saveTokenToDatabase(token);
    });

    _isInitialized = true;
  }

  // Retrieve current token and store it in database
  Future<void> registerDeviceToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }
    } catch (e) {
      print("Error getting device token: $e");
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    // We use Firebase User ID for our user id in the profiles table
    if (userId == null) {
      // If we are not logged in yet, we cannot save the token.
      return;
    }

    try {
      await _supabase
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', userId);
      print("FCM token saved successfully.");
    } catch (e) {
      print("Failed to save FCM token to database: $e");
    }
  }

  // Send push notification to a target audience
  Future<void> sendNoticeNotification({
    required String title,
    required String body,
    required String audience,
    String? specificStudentId,
  }) async {
    try {
      // 1. Fetch Firebase Service Account JSON from secrets table
      final secretData = await _supabase
          .from('secrets')
          .select('value')
          .eq('key', 'firebase_service_account')
          .maybeSingle();

      if (secretData == null) {
        print(
          "Firebase service account credentials not found in secrets table.",
        );
        return;
      }

      final Map<String, dynamic> serviceAccount = jsonDecode(
        secretData['value'] as String,
      );

      final projectId = serviceAccount['project_id'] as String?;
      if (projectId == null) {
        print("Project ID not found in service account json.");
        return;
      }

      // 2. Query target student FCM tokens
      List<String> targetTokens = [];

      if (audience == 'All') {
        final response = await _supabase
            .from('profiles')
            .select('fcm_token')
            .eq('role', 'student')
            .not('fcm_token', 'is', null);

        targetTokens = List<String>.from(
          (response as List).map((e) => e['fcm_token'] as String),
        );
      } else if (audience == 'Specific' && specificStudentId != null) {
        final response = await _supabase
            .from('profiles')
            .select('fcm_token')
            .eq('id', specificStudentId)
            .maybeSingle();

        if (response != null && response['fcm_token'] != null) {
          targetTokens = [response['fcm_token'] as String];
        }
      } else {
        // Audience is a specific category (e.g. LKG, Nursery)
        final response = await _supabase
            .from('profiles')
            .select('fcm_token')
            .eq('role', 'student')
            .eq('student_type', audience)
            .not('fcm_token', 'is', null);

        targetTokens = List<String>.from(
          (response as List).map((e) => e['fcm_token'] as String),
        );
      }

      if (targetTokens.isEmpty) {
        print("No target FCM tokens found to notify.");
        return;
      }

      // 3. Get OAuth2 Client using the service account credentials
      final credentials = auth.ServiceAccountCredentials.fromJson(
        serviceAccount,
      );
      final client = await auth.clientViaServiceAccount(credentials, [
        'https://www.googleapis.com/auth/firebase.messaging',
      ]);

      // 4. Send to all targets via FCM HTTP v1 API
      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      );

      for (final token in targetTokens) {
        final payload = {
          'message': {
            'token': token,
            'notification': {'title': title, 'body': body},
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'title': title,
              'body': body,
            },
          },
        };

        try {
          final res = await client.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          );
          if (res.statusCode == 200) {
            print("Successfully sent push notification to: $token");
          } else {
            print("FCM send error (${res.statusCode}): ${res.body}");
          }
        } catch (err) {
          print("FCM post failed: $err");
        }
      }

      client.close();
    } catch (e) {
      print("Error sending notice push notifications: $e");
    }
  }
}
