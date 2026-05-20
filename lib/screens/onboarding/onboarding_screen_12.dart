import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/visual_settings_provider.dart';
import '../../widgets/candle_widget.dart';
import '../../widgets/onboarding_action_button.dart';

class OnboardingScreen12 extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onBack;

  const OnboardingScreen12({super.key, required this.onComplete, this.onBack});

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
    await _flameController.forward();

    final onboarding = context.read<OnboardingProvider>();

    await onboarding.completeOnboarding();

    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visualSettings = context.read<VisualSettingsProvider>();

    return Scaffold(
      backgroundColor: visualSettings.backgroundOuterColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 1.05).animate(
                        CurvedAnimation(
                          parent: _flameController,
                          curve: Curves.easeOut,
                        ),
                      ),
                      child: CandleWidget(
                        size: 180,
                        candleColor: visualSettings.candleBodyColor,
                        isAnimated: true,
                        flameScale: 0.55,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    const Text(
                      'You are all set!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Take a breath, start small, and let the candle guide you into your first focused session.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.74),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _EncouragementCard(
                      icon: Icons.auto_awesome_rounded,
                      title: 'A calmer way to begin',
                      description:
                          'Your focus ritual is ready whenever you are. No pressure, just a better first step.',
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: OnboardingActionButton(
                label: _flameController.isCompleted
                    ? 'Starting...'
                    : "Let’s Go",
                onPressed: _flameController.isCompleted ? null : _lightCandle,
                disabledBackgroundColor: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EncouragementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _EncouragementCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFD9B14D).withOpacity(0.16),
              border: Border.all(
                color: const Color(0xFFD9B14D).withOpacity(0.32),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFD9B14D),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 14,
                    height: 1.45,
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
