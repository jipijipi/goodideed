import 'package:flutter/material.dart';
import 'widgets/chat_screen.dart';
import 'services/user_data_service.dart';
import 'services/session_service.dart';
import 'themes/app_themes.dart';
import 'constants/app_constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  bool _isInitialized = false;
  late final UserDataService _userDataService;
  late final SessionService _sessionService;

  @override
  void initState() {
    super.initState();
    _userDataService = UserDataService();
    _sessionService = SessionService(_userDataService);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Ensure SessionService completes BEFORE ChatScreen initializes
    await _sessionService.initializeSession();
    await _loadThemePreference();
    
    // Mark initialization as complete
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _loadThemePreference() async {
    final isDark = await _userDataService.getValue<bool>(AppThemes.themeKey) ?? false;
    setState(() {
      _isDarkMode = isDark;
    });
  }

  Future<void> _toggleTheme() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    await _userDataService.storeValue(AppThemes.themeKey, _isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: AppThemes.getThemeMode(_isDarkMode),
      home: _isInitialized 
        ? ChatScreen(onThemeToggle: _toggleTheme)
        : const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
    );
  }
}
