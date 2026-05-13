import 'package:ai_tutor_grad_project/services/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'constants/app_colors.dart';
import 'constants/app_typography.dart';
import 'constants/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TTSService.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eshrhly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.surface,
        textTheme: TextTheme(
          displayLarge: AppTextStyles.heading1,
          bodyLarge: AppTextStyles.body,
          bodySmall: AppTextStyles.caption,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
        ),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.onboarding,
      // Use the route generator instead of a static 'routes' map
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}