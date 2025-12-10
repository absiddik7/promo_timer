import 'package:flutter/material.dart';
import 'dart:math' as math;

class WaterGlassPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  WaterGlassPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.6;
    final glassHeight = size.height * 0.55;
    final glassWidth = size.width * 0.35;

    // Draw glass container
    _drawGlassContainer(canvas, centerX, centerY, glassHeight, glassWidth);

    // Draw water fill
    _drawWaterFill(canvas, centerX, centerY, glassHeight, glassWidth);

    // Draw water surface
    _drawWaterSurface(canvas, centerX, centerY, glassHeight, glassWidth);

    // Draw bubbles
    _drawBubbles(canvas, centerX, centerY, glassHeight, glassWidth);

    // Draw glass reflections
    _drawReflections(canvas, centerX, centerY, glassHeight, glassWidth);
  }

  void _drawGlassContainer(Canvas canvas, double centerX, double centerY,
      double height, double width) {
    final glassPaint = Paint()
      ..color = Color(0xFFB0BEC5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw glass cylinder
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: width,
        height: height,
      ),
      glassPaint,
    );

    // Draw glass bottom
    final bottomPaint = Paint()
      ..color = Color(0xFF90A4AE).withOpacity(0.5)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(centerX - width / 2, centerY + height / 2),
      Offset(centerX + width / 2, centerY + height / 2),
      bottomPaint,
    );
  }

  void _drawWaterFill(Canvas canvas, double centerX, double centerY,
      double height, double width) {
    final waterHeight = height * 0.95 * progress;
    final waterBottomY = centerY + height / 2;
    final waterTopY = waterBottomY - waterHeight;

    // Water gradient (depth-based)
    final waterGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF81D4FA).withOpacity(0.5),
        Color(0xFF4FC3F7).withOpacity(0.7),
        Color(0xFF29B6F6).withOpacity(0.85),
      ],
    );

    final waterPaint = Paint()
      ..shader = waterGradient.createShader(
        Rect.fromLTWH(
          centerX - width / 2,
          waterTopY,
          width,
          waterHeight,
        ),
      );

    canvas.drawRect(
      Rect.fromLTWH(
        centerX - width / 2 + 1.5,
        waterTopY,
        width - 3,
        waterHeight,
      ),
      waterPaint,
    );
  }

  void _drawWaterSurface(Canvas canvas, double centerX, double centerY,
      double height, double width) {
    if (progress <= 0) return;

    final waterHeight = height * 0.95 * progress;
    final waterBottomY = centerY + height / 2;
    final waterTopY = waterBottomY - waterHeight;

    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;

    // Draw wave surface
    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1.5;

    final path = Path();
    path.moveTo(centerX - width / 2, waterTopY);

    for (double x = centerX - width / 2; x <= centerX + width / 2; x += 5) {
      final waveOffset = 3 * math.sin((x / 20 + time * 2) * math.pi);
      path.lineTo(x, waterTopY + waveOffset);
    }

    path.lineTo(centerX + width / 2, waterTopY);
    canvas.drawPath(path, wavePaint);

    // Draw foam highlights
    final foamPaint = Paint()
      ..color = Colors.white.withOpacity(0.6);

    for (int i = 0; i < 5; i++) {
      final foamX = centerX - width / 2 + (i + 1) * (width / 6);
      final foamWave = 3 * math.sin((foamX / 20 + time * 2) * math.pi);
      canvas.drawCircle(Offset(foamX, waterTopY + foamWave - 2), 1.5, foamPaint);
    }
  }

  void _drawBubbles(Canvas canvas, double centerX, double centerY,
      double height, double width) {
    final waterHeight = height * 0.95 * progress;
    final waterBottomY = centerY + height / 2;
    final waterTopY = waterBottomY - waterHeight;

    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final random = math.Random(42);

    final bubbleCount = (8 + progress * 4).toInt();

    for (int i = 0; i < bubbleCount; i++) {
      final bubbleTime = time + (i * 0.8);
      final bubblePhase = (bubbleTime % 3) / 3;

      if (bubblePhase < 1.0) {
        final bubbleX = centerX - width / 2 + random.nextDouble() * width;
        final bubbleY = waterBottomY - (bubblePhase * waterHeight);
        final bubbleSize = 4 + random.nextDouble() * 6;
        final wobble = 0.95 + 0.1 * math.sin(bubbleTime * 4 * math.pi);

        // Bubble body
        final bubblePaint = Paint()
          ..color = Color(0xFFE1F5FE).withOpacity(0.4)
          ..strokeWidth = 1
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(bubbleX, bubbleY),
          bubbleSize * wobble,
          bubblePaint,
        );

        // Bubble stroke
        final bubbleStroke = Paint()
          ..color = Color(0xFFB3E5FC).withOpacity(0.6)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

        canvas.drawCircle(
          Offset(bubbleX, bubbleY),
          bubbleSize * wobble,
          bubbleStroke,
        );

        // Bubble highlight
        final highlightPaint = Paint()
          ..color = Colors.white.withOpacity(0.5);

        canvas.drawCircle(
          Offset(bubbleX - bubbleSize * wobble / 3, bubbleY - bubbleSize * wobble / 3),
          bubbleSize * wobble * 0.3,
          highlightPaint,
        );
      }
    }
  }

  void _drawReflections(Canvas canvas, double centerX, double centerY,
      double height, double width) {
    final reflectionPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 3;

    // Left edge highlight
    canvas.drawLine(
      Offset(centerX - width / 2 + 1.5, centerY - height / 2),
      Offset(centerX - width / 2 + 1.5, centerY + height / 2),
      reflectionPaint,
    );

    // Right edge shadow
    final shadowPaint = Paint()
      ..color = Color(0xFF90A4AE).withOpacity(0.2)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(centerX + width / 2 - 1.5, centerY - height / 2),
      Offset(centerX + width / 2 - 1.5, centerY + height / 2),
      shadowPaint,
    );
  }

  @override
  bool shouldRepaint(WaterGlassPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
