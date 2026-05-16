import 'package:flutter/material.dart';

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

class _OnboardingScreen7State extends State<OnboardingScreen7>
    with SingleTickerProviderStateMixin {
  late AnimationController _meltController;

  @override
  void initState() {
    super.initState();
    _meltController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _meltController.forward();
  }

  @override
  void dispose() {
    _meltController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1320),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Animated candle demo
                    AnimatedBuilder(
                      animation: _meltController,
                      builder: (context, child) {
                        return SizedBox(
                          width: 140,
                          height: 200,
                          child: CustomPaint(
                            painter: _CandleDemoPainter(
                              meltProgress: _meltController.value,
                            ),
                          ),
                        );
                      },
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
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F1320),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Make it yours',
                    style: TextStyle(
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

class _CandleDemoPainter extends CustomPainter {
  final double meltProgress;

  _CandleDemoPainter({required this.meltProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Background
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, height),
        Radius.circular(width * 0.1),
      ),
      bgPaint,
    );

    // Calculate melt amount
    final meltAmount = height * 0.4 * meltProgress;

    // Candle body with reduced height based on melt
    final bodyHeight = height * 0.5 - meltAmount;
    final bodyY = height * 0.25 + meltAmount;

    final bodyPaint = Paint()
      ..color = const Color(0xFFD4C4A0)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          width * 0.25,
          bodyY,
          width * 0.5,
          bodyHeight,
        ),
        Radius.circular(width * 0.08),
      ),
      bodyPaint,
    );

    // Growing pool at base
    final poolHeight = height * 0.15 * meltProgress;
    final poolPaint = Paint()
      ..color = const Color(0xFFC4B5A0)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(width / 2, height * 0.85 - poolHeight * 0.3),
        width: width * 0.6 + (width * 0.3 * meltProgress),
        height: poolHeight,
      ),
      poolPaint,
    );

    // Wax drips
    if (meltProgress > 0.1) {
      final dripPaint = Paint()
        ..color = const Color(0xFFC4B5A0)
        ..style = PaintingStyle.fill;

      final dripCount = (meltProgress * 5).toInt();
      for (int i = 0; i < dripCount; i++) {
        final dripY = height * 0.75 + (height * 0.15 * (i / 5));
        final dripOpacity = 1.0 - (i / 5) * meltProgress;

        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(width * 0.15, dripY),
            width: width * 0.06,
            height: height * 0.08,
          ),
          Paint()
            ..color = const Color(0xFFC4B5A0).withOpacity(dripOpacity)
            ..style = PaintingStyle.fill,
        );

        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(width * 0.85, dripY),
            width: width * 0.06,
            height: height * 0.08,
          ),
          Paint()
            ..color = const Color(0xFFC4B5A0).withOpacity(dripOpacity)
            ..style = PaintingStyle.fill,
        );
      }
    }

    // Flame (stays same height if candle still visible)
    if (bodyHeight > 0 && meltProgress < 0.9) {
      final flameScale = 0.8 + (0.2 * meltProgress);

      final flamePaint = Paint()
        ..color = Color.lerp(
          const Color(0xFFFFA500),
          const Color(0xFFFFCC00),
          0.5,
        )!
        ..style = PaintingStyle.fill;

      final flameX = width / 2;
      final flameY = bodyY - (height * 0.1 * flameScale);

      final flamePath = Path();
      flamePath.moveTo(flameX, flameY - (height * 0.1 * flameScale));
      flamePath.quadraticBezierTo(
        flameX - (width * 0.04 * flameScale),
        flameY - (height * 0.05 * flameScale),
        flameX - (width * 0.02 * flameScale),
        flameY,
      );
      flamePath.quadraticBezierTo(
        flameX - (width * 0.01 * flameScale),
        flameY + (height * 0.03 * flameScale),
        flameX,
        flameY + (height * 0.015 * flameScale),
      );
      flamePath.quadraticBezierTo(
        flameX + (width * 0.01 * flameScale),
        flameY + (height * 0.03 * flameScale),
        flameX + (width * 0.02 * flameScale),
        flameY,
      );
      flamePath.quadraticBezierTo(
        flameX + (width * 0.04 * flameScale),
        flameY - (height * 0.05 * flameScale),
        flameX,
        flameY - (height * 0.1 * flameScale),
      );
      flamePath.close();

      canvas.drawPath(flamePath, flamePaint);
    }
  }

  @override
  bool shouldRepaint(_CandleDemoPainter oldDelegate) {
    return oldDelegate.meltProgress != meltProgress;
  }
}
