import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/visual_settings_provider.dart';
import '../../providers/timer_provider.dart';
import '../../widgets/candle_widget.dart';
import '../../widgets/onboarding_action_button.dart';

class OnboardingScreen12 extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onBack;

  const OnboardingScreen12({
    super.key,
    required this.onComplete,
    this.onBack,
  });

  @override
  State<OnboardingScreen12> createState() => _OnboardingScreen12State();
}

class _OnboardingScreen12State extends State<OnboardingScreen12>
    with SingleTickerProviderStateMixin {
  late AnimationController _flameController;

  @override
  void initState() {
    super.initState();
    _flameController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _flameController.dispose();
    super.dispose();
  }

  Future<void> _lightCandle() async {
    // Start the flame animation
    await _flameController.forward();

    // Apply session duration from survey
    final onboarding = context.read<OnboardingProvider>();
    final timerProvider = context.read<TimerProvider>();

    // Set timer duration if a specific value was chosen
    if (onboarding.sessionDuration != null && onboarding.sessionDuration! > 0) {
      await timerProvider.setDurationMinutes(onboarding.sessionDuration!);
    } else {
      // Default to 25 minutes (Pomodoro)
      await timerProvider.setDurationMinutes(25);
    }

    // Set selected sound if available
    if (onboarding.soundPreference != null) {
      // TODO: Apply sound setting from survey
    }

    // Mark onboarding as complete
    await onboarding.completeOnboarding();

    // Navigate to main app
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visualSettings = context.read<VisualSettingsProvider>();
    final onboarding = context.read<OnboardingProvider>();

    // Format session duration for display
    final sessionMinutes = onboarding.sessionDuration ?? 25;
    final displayMinutes = sessionMinutes > 0 ? sessionMinutes : 25;

    return Scaffold(
      backgroundColor: visualSettings.backgroundOuterColor,
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Animated personalized candle
                ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.05).animate(
                    CurvedAnimation(parent: _flameController, curve: Curves.easeOut),
                  ),
                  child: CandleWidget(
                    size: 240,
                    candleColor: visualSettings.candleBodyColor,
                    isAnimated: false,
                  ),
                ),
                const SizedBox(height: 48),
                // Session info
                Text(
                  'Your $displayMinutes-minute session is ready.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: OnboardingActionButton(
              label: _flameController.isCompleted ? 'Starting...' : 'Light the candle',
              onPressed: _flameController.isCompleted ? null : _lightCandle,
              disabledBackgroundColor: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

