import 'package:flutter/material.dart';
import '../../widgets/candle_widget.dart';
import '../../widgets/onboarding_action_button.dart';

class OnboardingScreen7 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const OnboardingScreen7({
    super.key,
    required this.onNext,
    this.onBack,
  });

  @override
  State<OnboardingScreen7> createState() => _OnboardingScreen7State();
}

class _OnboardingScreen7State extends State<OnboardingScreen7> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1320),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animated candle demo
                  const CandleWidget(
                    size: 280,
                    duration: Duration(seconds: 10),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'This is your timer.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      textBaseline: TextBaseline.alphabetic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'As you focus, the candle burns. When the wax is gone, your session is done.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFB8A89F),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: OnboardingActionButton(
              label: 'Make it yours',
              onPressed: widget.onNext,
            ),
          ),
        ],
      ),
    );
  }
}
