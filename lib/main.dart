import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_colors.dart';
import 'features/splash/splash_view.dart';

import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyANN9QwWbgRz1b-N7eEHNoMek0EdBAlr-w',
          appId: '1:563646488257:android:80301046032e74206cbe40',
          messagingSenderId: '563646488257',
          projectId: 'nutrimind-ec817',
          storageBucket: 'nutrimind-ec817.firebasestorage.app',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyANN9QwWbgRz1b-N7eEHNoMek0EdBAlr-w',
          appId: '1:563646488257:android:80301046032e74206cbe40',
          messagingSenderId: '563646488257',
          projectId: 'nutrimind-ec817',
          storageBucket: 'nutrimind-ec817.firebasestorage.app',
        ),
      );
    } catch (e2) {
      debugPrint('Firebase initialization failed: $e2');
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriMind AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
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
      home: const SplashView(),
    );
  }
}
