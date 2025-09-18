import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'widgets/chat_screen.dart';
//import 'widgets/rive_test_widget.dart';
//import 'widgets/rive_data_binding_test_widget.dart';
//import 'widgets/rive_arm_test_widget.dart';
import 'services/service_locator.dart';
import 'services/session_service.dart';
import 'services/logger_service.dart';
import 'themes/app_themes.dart';
import 'constants/app_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RiveNative.init(); // Required for Rive 0.14.0
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
  late final SessionService _sessionService;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final logger = LoggerService.instance;
    final overallStopwatch = Stopwatch()..start();
    final timings = <String, int>{};

    logger.info('🚀 App initialization started');

    try {
      // Initialize all application services first
      final serviceStopwatch = Stopwatch()..start();
      await ServiceLocator.instance.initialize();
      timings['ServiceLocator'] = serviceStopwatch.elapsedMilliseconds;
      logger.info('⚙️  ServiceLocator initialized: ${timings['ServiceLocator']}ms');

      // Get session service from ServiceLocator and initialize it
      final sessionStopwatch = Stopwatch()..start();
      _sessionService = ServiceLocator.instance.sessionService;
      await _sessionService.initializeSession();
      timings['SessionService'] = sessionStopwatch.elapsedMilliseconds;
      logger.info('📊 SessionService initialized: ${timings['SessionService']}ms');

      // Load theme preference
      final themeStopwatch = Stopwatch()..start();
      await _loadThemePreference();
      timings['ThemePreference'] = themeStopwatch.elapsedMilliseconds;
      logger.info('🎨 Theme preference loaded: ${timings['ThemePreference']}ms');

      // Mark initialization as complete
      setState(() {
        _isInitialized = true;
      });

      final totalTime = overallStopwatch.elapsedMilliseconds;
      logger.info('✅ App initialization completed in ${totalTime}ms');
      logger.info('📈 Timing breakdown: ServiceLocator=${timings['ServiceLocator']}ms, SessionService=${timings['SessionService']}ms, Theme=${timings['ThemePreference']}ms');

    } catch (e) {
      final totalTime = overallStopwatch.elapsedMilliseconds;
      logger.error('❌ App initialization failed after ${totalTime}ms: $e');
      rethrow;
    }
  }

  Future<void> _loadThemePreference() async {
    final userDataService = ServiceLocator.instance.userDataService;
    final isDark =
        await userDataService.getValue<bool>(AppThemes.themeKey) ?? false;
    setState(() {
      _isDarkMode = isDark;
    });
  }

  Future<void> _toggleTheme() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    final userDataService = ServiceLocator.instance.userDataService;
    await userDataService.storeValue(AppThemes.themeKey, _isDarkMode);
  }

  @override
  void dispose() {
    ServiceLocator.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: AppThemes.getThemeMode(_isDarkMode),
      home:
          _isInitialized
              ? ChatScreen(
                onThemeToggle: _toggleTheme,
              ) // const RiveArmTestWidget() // const RiveDataBindingTestWidget() // const RiveTestWidget()
              : const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
    );
  }
}
