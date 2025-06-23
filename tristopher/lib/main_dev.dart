import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tristopher_app/constants/app_constants.dart';
import 'package:tristopher_app/screens/account/account_screen.dart';
//import 'package:tristopher_app/screens/auth/onboarding_screen.dart';
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
  // Firebase is used to store user data, conversation history, and handle wager transactions
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
  
  // Start the app with Riverpod state management for conversation flow
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
              color: Colors.black.withAlpha((0.2 * 255).toInt()),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Colors.black.withAlpha((0.2 * 255).toInt()),
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
          scrimColor: Colors.black.withAlpha(128),
          elevation: 4,
        ),
      ),
      // DAILY CONVERSATION FLOW OVERVIEW:
      // The main conversation happens in MainChatScreen, following these key steps:
      //
      // STEP 1: App Launch & Initialization
      // - Start at splash screen, then navigate to main chat
      // - ConversationEngine loads user state and current day's script
      //
      // STEP 2: User Status Assessment (in conversation_engine.dart)
      // - Check if user is onboarded (has_name, knows_concept)
      // - Check if daily task is set (has_task_set)
      // - Check if task deadline has passed (is_overdue)
      //
      // STEP 3A: First-time User Onboarding Flow
      // - Collect user name
      // - Explain anti-charity concept
      // - Set daily task and deadline
      // - Configure notification preferences
      // - Set wager amount and target organization
      //
      // STEP 3B: Returning User - Task Status Check
      // - If task overdue: Ask for completion status (completed/failed/still working)
      // - If task current: Check progress (completed early/in progress/not started)
      //
      // STEP 4: Response Processing & Consequences
      // - Success: Increment streak, congratulate, continue or change task
      // - Failure: Handle excuse system (first excuse = "on notice", second = wager loss)
      // - Wager Loss: Transfer money to anti-charity, reset streak
      //
      // STEP 5: Next Steps & Sendoff
      // - Set expectations for next check-in
      // - Remind of consequences
      // - Store updated state in database
      
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        //AppRoutes.onboarding: (context) => const OnboardingScreen(),
        // MAIN CHAT: Where the daily conversation magic happens
        AppRoutes.mainChat: (context) => const MainChatScreen(),
        AppRoutes.goalStake: (context) => const GoalScreen(),
        AppRoutes.account: (context) => const AccountScreen(),
      },
    );
  }
}
