import 'package:flutter/material.dart';

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

    // Auto-advance after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        widget.onNext();
      }
    });
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated candle
            ScaleTransition(
              scale: _candleAnimation,
              child: SizedBox(
                width: 120,
                height: 160,
                child: CustomPaint(
                  painter: _CandlePainter(
                    flameScale: _candleAnimation.value,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
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
    );
  }
}

class _CandlePainter extends CustomPainter {
  final double flameScale;

  _CandlePainter({required this.flameScale});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Candle body
    final bodyRect = Rect.fromLTWH(
      width * 0.25,
      height * 0.3,
      width * 0.5,
      height * 0.5,
    );

    final bodyPaint = Paint()
      ..color = const Color(0xFFD4C4A0)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(width * 0.08)),
      bodyPaint,
    );

    // Wax pool at base
    final poolPaint = Paint()
      ..color = const Color(0xFFC4B5A0)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(width / 2, height * 0.8),
        width: width * 0.6,
        height: height * 0.2,
      ),
      poolPaint,
    );

    // Flame
    if (flameScale > 0) {
      final flamePaint = Paint()
        ..color = Color.lerp(
          const Color(0xFFFFA500),
          const Color(0xFFFFCC00),
          0.5,
        )!
        ..style = PaintingStyle.fill;

      final flameX = width / 2;
      final flameY = height * 0.3 - (height * 0.15 * flameScale);

      // Flame shape using path
      final flamePath = Path();
      flamePath.moveTo(flameX, flameY - (height * 0.12 * flameScale));
      flamePath.quadraticBezierTo(
        flameX - (width * 0.05 * flameScale),
        flameY - (height * 0.06 * flameScale),
        flameX - (width * 0.03 * flameScale),
        flameY,
      );
      flamePath.quadraticBezierTo(
        flameX - (width * 0.01 * flameScale),
        flameY + (height * 0.04 * flameScale),
        flameX,
        flameY + (height * 0.02 * flameScale),
      );
      flamePath.quadraticBezierTo(
        flameX + (width * 0.01 * flameScale),
        flameY + (height * 0.04 * flameScale),
        flameX + (width * 0.03 * flameScale),
        flameY,
      );
      flamePath.quadraticBezierTo(
        flameX + (width * 0.05 * flameScale),
        flameY - (height * 0.06 * flameScale),
        flameX,
        flameY - (height * 0.12 * flameScale),
      );
      flamePath.close();

      canvas.drawPath(flamePath, flamePaint);
    }
  }

  @override
  bool shouldRepaint(_CandlePainter oldDelegate) {
    return oldDelegate.flameScale != flameScale;
  }
}
