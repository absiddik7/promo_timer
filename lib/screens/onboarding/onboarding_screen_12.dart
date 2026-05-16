import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/visual_settings_provider.dart';
import '../../providers/timer_provider.dart';

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
    //await onboarding.completeOnboarding();

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
      body: SafeArea(
        child: Column(
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
                    child: SizedBox(
                      width: 160,
                      height: 220,
                      child: CustomPaint(
                        painter: _PersonalizedCandlePainter(
                          candleColor: visualSettings.candleBodyColor,
                          flameScale: _flameController.value,
                        ),
                      ),
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
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _flameController.isCompleted ? null : _lightCandle,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F1320),
                    disabledBackgroundColor: Colors.white.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _flameController.isCompleted ? 'Starting...' : 'Light the candle',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalizedCandlePainter extends CustomPainter {
  final Color candleColor;
  final double flameScale;

  _PersonalizedCandlePainter({
    required this.candleColor,
    required this.flameScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Candle body
    final bodyRect = Rect.fromLTWH(
      width * 0.2,
      height * 0.25,
      width * 0.6,
      height * 0.5,
    );

    final bodyPaint = Paint()
      ..color = candleColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(width * 0.08)),
      bodyPaint,
    );

    // Wax pool
    final poolPaint = Paint()
      ..color = candleColor.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(width / 2, height * 0.8),
        width: width * 0.65,
        height: height * 0.2,
      ),
      poolPaint,
    );

    // Flame (grows with flameScale)
    if (flameScale > 0.1) {
      final flamePaint = Paint()
        ..color = Color.lerp(
          const Color(0xFFFFA500),
          const Color(0xFFFFCC00),
          0.5,
        )!
        ..style = PaintingStyle.fill;

      final flameX = width / 2;
      final flameBaseY = height * 0.25;
      final flameScale = 0.8 + (0.4 * this.flameScale);

      final flamePath = Path();
      flamePath.moveTo(flameX, flameBaseY - (height * 0.15 * flameScale));
      flamePath.quadraticBezierTo(
        flameX - (width * 0.06 * flameScale),
        flameBaseY - (height * 0.08 * flameScale),
        flameX - (width * 0.03 * flameScale),
        flameBaseY,
      );
      flamePath.quadraticBezierTo(
        flameX - (width * 0.01 * flameScale),
        flameBaseY + (height * 0.04 * flameScale),
        flameX,
        flameBaseY + (height * 0.02 * flameScale),
      );
      flamePath.quadraticBezierTo(
        flameX + (width * 0.01 * flameScale),
        flameBaseY + (height * 0.04 * flameScale),
        flameX + (width * 0.03 * flameScale),
        flameBaseY,
      );
      flamePath.quadraticBezierTo(
        flameX + (width * 0.06 * flameScale),
        flameBaseY - (height * 0.08 * flameScale),
        flameX,
        flameBaseY - (height * 0.15 * flameScale),
      );
      flamePath.close();

      canvas.drawPath(flamePath, flamePaint);
    }
  }

  @override
  bool shouldRepaint(_PersonalizedCandlePainter oldDelegate) {
    return oldDelegate.flameScale != flameScale ||
        oldDelegate.candleColor.value != candleColor.value;
  }
}
