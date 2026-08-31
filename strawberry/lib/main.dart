import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strawberry/core/supabase_config.dart';
import 'package:strawberry/core/theme/app_theme.dart';
import 'package:strawberry/features/splash/splash_screen.dart';
import 'package:strawberry/features/auth/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyCb-CwE-hMPQ6Ofbq9Ag0im719tc_7Z2u4',
          appId: '1:246316625668:web:8ad5313a1874fdfa99aa51',
          messagingSenderId: '246316625668',
          projectId: 'strawberrymobile-ea8a1',
          authDomain: 'strawberrymobile-ea8a1.firebaseapp.com',
          storageBucket: 'strawberrymobile-ea8a1.firebasestorage.app',
        ),
      );
    } else {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await PushNotificationService().initialize();
    }
  } catch (e) {
    debugPrint('Firebase init: $e');
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    // ignore: deprecated_member_use
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Strawberry Preschool',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
