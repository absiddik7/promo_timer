import 'package:flutter/material.dart';
import '../../widgets/candle_widget.dart';
import '../../widgets/onboarding_action_button.dart';

class OnboardingScreen1 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const OnboardingScreen1({
    super.key,
    required this.onNext,
    this.onBack,
  });

  @override
  State<OnboardingScreen1> createState() => _OnboardingScreen1State();
}

class _OnboardingScreen1State extends State<OnboardingScreen1>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _candleAnimation;
  late Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _candleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1320),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated (live) candle
                    ScaleTransition(
                      scale: _candleAnimation,
                      child: const CandleWidget(
                        size: 300,
                        isAnimated: true,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // App name
                    const Text(
                      'Candle Timer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tagline
                    FadeTransition(
                      opacity: _taglineOpacity,
                      child: const Text(
                        'Focus, beautifully.',
                        style: TextStyle(
                          color: Color(0xFFB8A89F),
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: OnboardingActionButton(
                label: 'Get Started',
                onPressed: widget.onNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


