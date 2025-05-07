import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tristopher_app/constants/app_constants.dart';
import 'package:tristopher_app/providers/providers.dart';
import 'package:tristopher_app/widgets/common/paper_background_widget.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  // Navigate to the next screen after a short delay
  void _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Check if onboarding is needed
    final needsOnboarding = await ref.read(needsOnboardingProvider.future);
    
    if (needsOnboarding) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.mainChat);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PaperBackgroundScaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/tristopher_logo.png',
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if image fails to load
                return Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.android_outlined,
                      size: 80,
                      color: AppColors.accentColor,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Tristopher',
              style: AppTextStyles.header(size: 36),
            ),
            const SizedBox(height: 8),
            Text(
              'Your pessimistic habit coach',
              style: AppTextStyles.userText(),
            ),
          ],
        ),
      ),
    );
  }
}
