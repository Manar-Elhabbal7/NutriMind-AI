import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_colors.dart';
import 'features/splash/splash_view.dart';
import 'features/home/services/notification_service.dart';

import 'package:flutter/foundation.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  const MyCustomScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  await NotificationService.instance.scheduleWaterReminders();
  try {
    if (kIsWeb) {
      const webAppId = String.fromEnvironment(
        'FIREBASE_WEB_APP_ID',
        defaultValue: '1:563646488257:web:23beedffebc4ca336cbe40',
      );
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: String.fromEnvironment(
            'FIREBASE_API_KEY',
            defaultValue: 'AIzaSyDZRdM_B2duZ1kPhH7PGGZWUwWbjq1sLBY',
          ),
          appId: webAppId,
          messagingSenderId: '563646488257',
          projectId: 'nutrimind-ec817',
          storageBucket: 'nutrimind-ec817.firebasestorage.app',
          measurementId: 'G-WMKWGCG936',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    if (kIsWeb) {
      debugPrint('Firebase Web initialization failed (running in offline/blocked mode): $e');
    } else {
      try {
        // Platform-specific fallback options on Mobile
        final isAndroid = defaultTargetPlatform == TargetPlatform.android;
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: isAndroid
                ? 'AIzaSyANN9QwWbgRz1b-N7eEHNoMek0EdBAlr-w'
                : 'AIzaSyBiL7q6cgy5iiZg5lPXjzS6fm6eAZIL_r8',
            appId: isAndroid
                ? '1:563646488257:android:80301046032e74206cbe40'
                : '1:563646488257:ios:90446bbdb14a53f86cbe40',
            messagingSenderId: '563646488257',
            projectId: 'nutrimind-ec817',
            storageBucket: 'nutrimind-ec817.firebasestorage.app',
            iosBundleId: isAndroid ? null : 'com.example.nutriMind',
          ),
        );
      } catch (e2) {
        debugPrint('Firebase initialization failed: $e2');
      }
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Global theme notifier for dynamic light/dark mode switching
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(
    ThemeMode.light,
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'NutriMind AI',
          debugShowCheckedModeBanner: false,
          scrollBehavior: const MyCustomScrollBehavior(),
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              surface: AppColors.surface,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: AppColors.background,
            cardTheme: CardThemeData(
              color: AppColors.surface,
              elevation: 2,
              shadowColor: AppColors.textPrimary.withAlpha(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            dividerTheme: const DividerThemeData(
              color: AppColors.border,
              thickness: 1,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              surface: const Color(0xFF1E1E1E),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardTheme: CardThemeData(
              color: const Color(0xFF1E1E1E),
              elevation: 2,
              shadowColor: Colors.black.withAlpha(40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            dividerTheme: const DividerThemeData(
              color: Color(0xFF2C2C2C),
              thickness: 1,
            ),
          ),
          home: const SplashView(),
        );
      },
    );
  }
}
