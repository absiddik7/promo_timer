import 'package:flutter/material.dart';
import 'dart:math' as math;

class HourglassPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  HourglassPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final hourglassHeight = size.height * 0.5;
    final hourglassWidth = size.width * 0.4;

    // Draw wooden frame
    _drawWoodenFrame(canvas, centerX, centerY, hourglassHeight, hourglassWidth);

    // Draw glass container
    _drawGlassContainer(canvas, centerX, centerY, hourglassHeight, hourglassWidth);

    // Draw sand
    _drawSand(canvas, centerX, centerY, hourglassHeight, hourglassWidth);

    // Draw sand stream
    _drawSandStream(canvas, centerX, centerY, hourglassHeight, hourglassWidth);

    // Draw glass reflections
    _drawReflections(canvas, centerX, centerY, hourglassHeight, hourglassWidth);
  }

  void _drawWoodenFrame(Canvas canvas, double centerX, double centerY, 
      double height, double width) {
    final frameHeight = height * 0.08;
    final frameWidth = width * 1.1;

    // Top frame
    final topFrameGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF8D6E63), Color(0xFF6D4C41)],
    );

    final topFramePaint = Paint()
      ..shader = topFrameGradient.createShader(
        Rect.fromLTWH(
          centerX - frameWidth / 2,
          centerY - height / 2 - frameHeight,
          frameWidth,
          frameHeight,
        ),
      );

    canvas.drawRect(
      Rect.fromLTWH(
        centerX - frameWidth / 2,
        centerY - height / 2 - frameHeight,
        frameWidth,
        frameHeight,
      ),
      topFramePaint,
    );

    // Bottom frame
    final bottomFramePaint = Paint()
      ..shader = topFrameGradient.createShader(
        Rect.fromLTWH(
          centerX - frameWidth / 2,
          centerY + height / 2,
          frameWidth,
          frameHeight,
        ),
      );

    canvas.drawRect(
      Rect.fromLTWH(
        centerX - frameWidth / 2,
        centerY + height / 2,
        frameWidth,
        frameHeight,
      ),
      bottomFramePaint,
    );
  }

  void _drawGlassContainer(Canvas canvas, double centerX, double centerY,
      double height, double width) {
    final bulbHeight = height * 0.45;
    final neckHeight = height * 0.1;
    final bulbWidth = width * 0.5;
    final neckWidth = bulbWidth * 0.15;

    final glassPaint = Paint()
      ..color = Color(0xFFE0F7FA).withOpacity(0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Top bulb
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY - height / 2 + bulbHeight / 2),
        width: bulbWidth,
        height: bulbHeight,
      ),
      glassPaint,
    );

    // Neck
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: neckWidth,
        height: neckHeight,
      ),
      glassPaint,
    );

    // Bottom bulb
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY + height / 2 - bulbHeight / 2),
        width: bulbWidth,
        height: bulbHeight,
      ),
      glassPaint,
    );

    // Draw glass fill (semi-transparent)
    final glassFillPaint = Paint()
      ..color = Color(0xFF90CAF9).withOpacity(0.1);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY - height / 2 + bulbHeight / 2),
        width: bulbWidth - 4,
        height: bulbHeight - 4,
      ),
      glassFillPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY + height / 2 - bulbHeight / 2),
        width: bulbWidth - 4,
        height: bulbHeight - 4,
      ),
      glassFillPaint,
    );
  }

  void _drawSand(Canvas canvas, double centerX, double centerY,
      double height, double width) {
    final bulbHeight = height * 0.45;
    final bulbWidth = width * 0.5;

    // Top sand (decreasing)
    final topSandLevel = (1 - progress) * bulbHeight * 0.9;
    final topSandGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFE082), Color(0xFFFFD54F), Color(0xFFFFB300)],
    );

    final topSandPaint = Paint()
      ..shader = topSandGradient.createShader(
        Rect.fromCenter(
          center: Offset(centerX, centerY - height / 2 + bulbHeight / 2),
          width: bulbWidth - 8,
          height: topSandLevel,
        ),
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY - height / 2 + bulbHeight / 2 - (bulbHeight * 0.9 - topSandLevel) / 2),
        width: bulbWidth - 8,
        height: topSandLevel,
      ),
      topSandPaint,
    );

    // Bottom sand (increasing)
    final bottomSandLevel = progress * bulbHeight * 0.9;
    final bottomSandGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFE082), Color(0xFFFFD54F), Color(0xFFFFB300)],
    );

    final bottomSandPaint = Paint()
      ..shader = bottomSandGradient.createShader(
        Rect.fromCenter(
          center: Offset(centerX, centerY + height / 2 - bulbHeight / 2),
          width: bulbWidth - 8,
          height: bottomSandLevel,
        ),
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY + height / 2 - bulbHeight / 2 + (bulbHeight * 0.9 - bottomSandLevel) / 2),
        width: bulbWidth - 8,
        height: bottomSandLevel,
      ),
      bottomSandPaint,
    );
  }

  void _drawSandStream(Canvas canvas, double centerX, double centerY,
      double height, double width) {
    if (progress >= 1.0) return;

    final neckWidth = width * 0.5 * 0.15;
    final streamPaint = Paint()
      ..color = Color(0xFFFFA726).withOpacity(0.6);

    final random = math.Random(42);
    final particleCount = (progress * 200).toInt();

    for (int i = 0; i < particleCount; i++) {
      final particleProgress = (i / particleCount);
      final particleY = centerY - (height * 0.05) + (particleProgress * height * 0.1);
      final particleX = centerX + (random.nextDouble() - 0.5) * neckWidth * 2;

      canvas.drawCircle(Offset(particleX, particleY), 1, streamPaint);
    }
  }

  void _drawReflections(Canvas canvas, double centerX, double centerY,
      double height, double width) {
    final bulbWidth = width * 0.5;
    final reflectionPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(centerX - bulbWidth / 2 + 2, centerY - height / 2),
      Offset(centerX - bulbWidth / 2 + 2, centerY + height / 2),
      reflectionPaint,
    );
  }

  @override
  bool shouldRepaint(HourglassPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
