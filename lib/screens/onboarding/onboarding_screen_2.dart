import 'package:flutter/material.dart';
import '../../widgets/onboarding_action_button.dart';

class OnboardingScreen2 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const OnboardingScreen2({super.key, required this.onNext, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1320),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Why it feels different',
                    style: TextStyle(
                      color: Color(0xFFB8A89F),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Not your boring timer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A focus ritual that feels alive, personal, and worth coming back to every day.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _FeatureCard(
                    icon: Icons.local_fire_department_rounded,
                    title: 'A candle that burns with you',
                    description:
                        'Watch your timer melt down in real time, so progress feels tangible instead of hidden behind numbers.',
                    accentColor: Color(0xFFD9B14D),
                  ),
                  const SizedBox(height: 14),
                  const _FeatureCard(
                    icon: Icons.music_note_rounded,
                    title: 'Soundscapes that settle your mind',
                    description:
                        'Layer in ambient audio that softens distractions and helps you drop into deep focus faster.',
                    accentColor: Color(0xFF84D6C8),
                  ),
                  const SizedBox(height: 14),
                  const _FeatureCard(
                    icon: Icons.palette_rounded,
                    title: 'Colors that feel like yours',
                    description:
                        'Tune the candle and mood to match the way you work, so the app feels like a ritual, not a template.',
                    accentColor: Color(0xFFFF8D6B),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: OnboardingActionButton(
              label: "Let's set it up",
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: accentColor.withOpacity(0.16),
              border: Border.all(color: accentColor.withOpacity(0.4)),
            ),
            child: Icon(icon, color: accentColor, size: 26),
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
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 14,
                    height: 1.5,
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
