import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tristopher_app/constants/app_constants.dart';
import 'package:tristopher_app/screens/account/account_screen.dart';
import 'package:tristopher_app/screens/auth/onboarding_screen.dart';
import 'package:tristopher_app/screens/goal_stake/goal_screen.dart';
import 'package:tristopher_app/screens/main_chat/enhanced_main_chat_screen.dart';
import 'package:tristopher_app/screens/splash/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tristopher_app/config/environment.dart';
import 'firebase_options_dev.dart' as firebase_dev;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set development environment
  EnvironmentConfig.setEnvironment(Environment.dev);
  
  // Initialize Firebase - ignore duplicate app errors
  try {
    await Firebase.initializeApp(
      options: firebase_dev.DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      // App already initialized, continue silently
    } else {
      // Re-throw other Firebase exceptions
      rethrow;
    }
  }
  
  runApp(
    const ProviderScope(
      child: TristopherApp(),
    ),
  );
}

class TristopherApp extends StatelessWidget {
  const TristopherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: EnvironmentConfig.appName,
      debugShowCheckedModeBanner: EnvironmentConfig.isDev,
      theme: ThemeData(
        // Use a custom theme with the specified colors and fonts
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentColor,
          primary: AppColors.accentColor,
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 252, 252, 246),
        textTheme: GoogleFonts.cutiveTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: AppTextStyles.header(size: 20),
          iconTheme: const IconThemeData(
            color: AppColors.primaryText,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentColor,
            foregroundColor: AppColors.primaryText,
            textStyle: AppTextStyles.buttonText(),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryText,
            textStyle: AppTextStyles.buttonText(),
            side: const BorderSide(color: AppColors.accentColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accentColor,
            textStyle: AppTextStyles.buttonText(),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Colors.black.withOpacity(0.2),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Colors.black.withOpacity(0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(
              color: AppColors.accentColor,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
        ),
        // Drawer theme settings
        drawerTheme: DrawerThemeData(
          backgroundColor: AppColors.backgroundColor,
          scrimColor: Colors.black.withOpacity(0.5),
          elevation: 4,
        ),
      ),
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.onboarding: (context) => const OnboardingScreen(),
        AppRoutes.mainChat: (context) => const MainChatScreen(),
        AppRoutes.goalStake: (context) => const GoalScreen(),
        AppRoutes.account: (context) => const AccountScreen(),
      },
    );
  }
}
