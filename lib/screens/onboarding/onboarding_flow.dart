import 'package:flutter/material.dart';
import '../../services/timer_notification_service.dart';
import '../../widgets/onboarding_progress_bar.dart';
import 'onboarding_screen_1.dart';
import 'onboarding_screen_2.dart';
import 'onboarding_screen_3.dart';
import 'onboarding_screen_4.dart';
import 'onboarding_screen_5.dart';
import 'onboarding_screen_6.dart';
import 'onboarding_screen_7.dart';
import 'onboarding_screen_8.dart';
import 'onboarding_screen_9.dart';
import 'onboarding_screen_11.dart';
import 'onboarding_screen_12.dart';

class OnboardingFlow extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingFlow({super.key, required this.onComplete});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentScreen = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _goToNextScreen() {
    if (_currentScreen < 10) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousScreen() {
    if (_currentScreen > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleScreenChanged(int index) {
    setState(() {
      _currentScreen = index;
    });

    // If reaching the notification permission screen, check whether it can be skipped.
    // With social proof removed from the flow, this screen is now index 9.
    if (index == 9) {
      _checkAndSkipNotificationScreen();
    }
  }

  Future<void> _checkAndSkipNotificationScreen() async {
    final isGranted = await TimerNotificationService.instance
        .isPermissionGranted();
    if (isGranted && mounted && _pageController.hasClients) {
      _pageController.jumpToPage(10);
    }
  }

  void _handleNotificationSkip() {
    // Skip notification permission and go to final screen
    _pageController.jumpToPage(10);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1320),
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: _currentScreen == 0
                  ? const SizedBox.shrink()
                  : OnboardingProgressBar(
                      currentScreen: _currentScreen,
                      totalScreens: 10,
                      onBackPressed: _currentScreen > 0
                          ? _goToPreviousScreen
                          : null,
                    ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: _handleScreenChanged,
                children: [
                  // Screen 1: Animated Splash
                  OnboardingScreen1(
                    onNext: _goToNextScreen,
                    onBack: _goToPreviousScreen,
                  ),
                  // Screen 2: What Makes This Different
                  OnboardingScreen2(
                    onNext: _goToNextScreen,
                    onBack: _goToPreviousScreen,
                  ),
                  // Screen 3: What are you focusing on?
                  OnboardingScreen3(
                    onNext: _goToNextScreen,
                    onBack: _goToPreviousScreen,
                  ),
                  // Screen 4: What gets in your way?
                  OnboardingScreen4(
                    onNext: _goToNextScreen,
                    onBack: _goToPreviousScreen,
                  ),
                  // Screen 5: How long can you focus?
                  OnboardingScreen5(
                    onNext: _goToNextScreen,
                    onBack: _goToPreviousScreen,
                  ),
                  // Screen 6: What helps you focus?
                  OnboardingScreen6(
                    onNext: _goToNextScreen,
                    onBack: _goToPreviousScreen,
                  ),
                  // Screen 7: The Candle (Live Feature Demo)
                  OnboardingScreen7(
                    onNext: _goToNextScreen,
                    onBack: _goToPreviousScreen,
                  ),
                  // Screen 8: Personalize: Candle & Background Color
                  OnboardingScreen8(
                    onNext: _goToNextScreen,
                    onBack: _goToPreviousScreen,
                  ),
                  // Screen 9: Personalize: Background Sound
                  OnboardingScreen9(
                    onNext: _goToNextScreen,
                    onBack: _goToPreviousScreen,
                  ),
                  // Screen 10: Notification Permission
                  OnboardingScreen11(
                    onNext: _goToNextScreen,
                    onSkip: _handleNotificationSkip,
                    onBack: _goToPreviousScreen,
                  ),
                  // Screen 11: Light Your First Candle
                  OnboardingScreen12(
                    onComplete: widget.onComplete,
                    onBack: _goToPreviousScreen,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
