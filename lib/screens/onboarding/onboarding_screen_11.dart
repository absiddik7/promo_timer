import 'package:flutter/material.dart';
import '../../widgets/onboarding_action_button.dart';

class OnboardingScreen11 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback? onBack;

  const OnboardingScreen11({
    super.key,
    required this.onNext,
    required this.onSkip,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1320),
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Candle icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFFD4C4A0),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 40),
                // Heading
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Know when your candle goes out.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Subtext
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "We'll let you know when your session ends so you can take a real break.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFB8A89F),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OnboardingActionButton(
                    label: 'Allow notifications',
                    onPressed: onNext,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OnboardingActionButton.outlined(
                    label: 'Not now',
                    onPressed: onSkip,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
