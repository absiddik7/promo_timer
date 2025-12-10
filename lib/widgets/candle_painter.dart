import 'package:flutter/material.dart';
import 'dart:math' as math;

class CandlePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Animation<double>? flameAnimation;

  CandlePainter({
    required this.progress,
    this.flameAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.6;

    // Draw background glow with enhanced radiance
    _drawBackgroundGlow(canvas, centerX, centerY, size);

    // Draw ambient light rays
    _drawLightRays(canvas, centerX, centerY, size);

    // Draw candle body with premium styling
    _drawCandleBody(canvas, centerX, centerY, size);

    // Draw melting wax pool at top
    _drawWaxPool(canvas, centerX, centerY, size);

    // Draw melting wax drips
    _drawWaxDrips(canvas, centerX, centerY, size);

    // Draw wick with charred effect
    _drawWick(canvas, centerX, centerY, size);

    // Draw flame with inner core
    _drawFlame(canvas, centerX, centerY, size);

    // Draw heat distortion effect
    _drawHeatDistortion(canvas, centerX, centerY, size);

    // Draw floating embers with trails
    _drawEmbers(canvas, centerX, centerY, size);

    // Draw smoke wisps
    _drawSmoke(canvas, centerX, centerY, size);
  }

  void _drawBackgroundGlow(Canvas canvas, double centerX, double centerY, Size size) {
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final glowPulse = 1.0 + 0.15 * math.sin(time * 2);
    final glowRadius = 180 * glowPulse;
    
    // Multiple layered glows for depth
    final glows = [
      (radius: glowRadius * 0.4, opacity: 0.6, colors: [Color(0xFFFFE082), Color(0xFFFFB74D)]),
      (radius: glowRadius * 0.7, opacity: 0.35, colors: [Color(0xFFFFB74D), Color(0xFFFF9800)]),
      (radius: glowRadius * 1.0, opacity: 0.15, colors: [Color(0xFFFF9800), Color(0xFFFF6F00)]),
    ];

    for (final glow in glows) {
      final gradient = RadialGradient(
        colors: [
          glow.colors[0].withOpacity(glow.opacity),
          glow.colors[1].withOpacity(glow.opacity * 0.5),
          glow.colors[1].withOpacity(0.0),
        ],
        stops: [0.0, 0.5, 1.0],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: Offset(centerX, centerY), radius: glow.radius),
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20);

      canvas.drawCircle(Offset(centerX, centerY), glow.radius, paint);
    }
  }

  void _drawLightRays(Canvas canvas, double centerX, double centerY, Size size) {
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final maxCandleHeight = size.height * 0.7;
    final candleHeight = maxCandleHeight * (1 - progress);
    final wickTopY = centerY - candleHeight;
    final flameY = wickTopY - 32;

    final rayCount = 8;
    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * 2 * math.pi + time * 0.3;
      final rayLength = 60 + 20 * math.sin(time * 2 + i);
      final opacity = 0.1 + 0.05 * math.sin(time * 3 + i);

      final startX = centerX + math.cos(angle) * 15;
      final startY = flameY + math.sin(angle) * 15;
      final endX = centerX + math.cos(angle) * rayLength;
      final endY = flameY + math.sin(angle) * rayLength;

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFE082).withOpacity(opacity),
          Color(0xFFFFE082).withOpacity(0.0),
        ],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromPoints(Offset(startX, startY), Offset(endX, endY)),
        )
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  void _drawCandleBody(Canvas canvas, double centerX, double centerY, Size size) {
    final candleWidth = size.width * 0.15;
    final maxCandleHeight = size.height * 0.7;
    final candleHeight = maxCandleHeight * (1 - progress);

    // Main candle body with realistic wax gradient
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0xFFE8D5C4),
        Color(0xFFFFF8DC),
        Color(0xFFFFEBCD),
        Color(0xFFFFF8DC),
        Color(0xFFD4C5B0),
      ],
      stops: [0.0, 0.2, 0.5, 0.8, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(
          centerX - candleWidth / 2,
          centerY - candleHeight,
          candleWidth,
          candleHeight,
        ),
      );

    // Draw candle body with slight taper
    final path = Path();
    path.moveTo(centerX - candleWidth / 2, centerY - candleHeight);
    path.lineTo(centerX + candleWidth / 2, centerY - candleHeight);
    path.lineTo(centerX + candleWidth / 2 * 0.92, centerY);
    path.lineTo(centerX - candleWidth / 2 * 0.92, centerY);
    path.close();

    canvas.drawPath(path, paint);

    // Add rim shadow at top for depth
    final rimGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF8B7355).withOpacity(0.3),
        Color(0xFF8B7355).withOpacity(0.0),
      ],
    );

    final rimPaint = Paint()
      ..shader = rimGradient.createShader(
        Rect.fromLTWH(
          centerX - candleWidth / 2,
          centerY - candleHeight,
          candleWidth,
          15,
        ),
      );

    canvas.drawRect(
      Rect.fromLTWH(
        centerX - candleWidth / 2,
        centerY - candleHeight,
        candleWidth,
        15,
      ),
      rimPaint,
    );

    // Enhanced edge highlights with dual tone
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1);

    canvas.drawLine(
      Offset(centerX - candleWidth / 2 + 1, centerY - candleHeight),
      Offset(centerX - candleWidth / 2 * 0.92 + 1, centerY),
      highlightPaint,
    );

    // Shadow side
    final shadowPaint = Paint()
      ..color = Color(0xFF8B7355).withOpacity(0.4)
      ..strokeWidth = 3
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawLine(
      Offset(centerX + candleWidth / 2 - 1, centerY - candleHeight),
      Offset(centerX + candleWidth / 2 * 0.92 - 1, centerY),
      shadowPaint,
    );

    // Subtle texture lines for realism
    final texturePaint = Paint()
      ..color = Color(0xFFD4C5B0).withOpacity(0.2)
      ..strokeWidth = 0.5;

    for (double i = 0.2; i < 1.0; i += 0.15) {
      final y = centerY - candleHeight * i;
      canvas.drawLine(
        Offset(centerX - candleWidth / 2 * 0.95, y),
        Offset(centerX + candleWidth / 2 * 0.95, y),
        texturePaint,
      );
    }
  }

  void _drawWaxPool(Canvas canvas, double centerX, double centerY, Size size) {
    final candleWidth = size.width * 0.15;
    final maxCandleHeight = size.height * 0.7;
    final candleHeight = maxCandleHeight * (1 - progress);
    final poolY = centerY - candleHeight;

    // Melted wax pool at top
    final poolDepth = 8 + progress * 5;
    
    final poolGradient = RadialGradient(
      colors: [
        Color(0xFFFFE082).withOpacity(0.8),
        Color(0xFFFFD54F).withOpacity(0.6),
        Color(0xFFFFEBCD).withOpacity(0.3),
      ],
      stops: [0.0, 0.5, 1.0],
    );

    final poolPaint = Paint()
      ..shader = poolGradient.createShader(
        Rect.fromCenter(
          center: Offset(centerX, poolY + poolDepth / 2),
          width: candleWidth * 0.9,
          height: poolDepth,
        ),
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, poolY + poolDepth / 2),
        width: candleWidth * 0.9,
        height: poolDepth,
      ),
      poolPaint,
    );

    // Glossy highlight on wax pool
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - 5, poolY + 3),
        width: candleWidth * 0.3,
        height: 4,
      ),
      highlightPaint,
    );
  }

  void _drawWaxDrips(Canvas canvas, double centerX, double centerY, Size size) {
    if (progress < 0.1) return;

    final candleWidth = size.width * 0.15;
    final random = math.Random(42);
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;

    for (int i = 0; i < 3; i++) {
      final dripX = centerX + (random.nextDouble() - 0.5) * candleWidth * 0.7;
      final dripProgress = (progress - 0.1) / 0.9;
      
      if (dripProgress > 0.3 * i && dripProgress < 0.3 * (i + 1) + 0.2) {
        final localProgress = (dripProgress - 0.3 * i) / 0.3;
        final double dripHeight = 35 * math.min(localProgress, 1.0);
        final wiggle = 2 * math.sin(time + i);

        // Drip gradient for 3D effect
        final dripGradient = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFD4C5B0),
            Color(0xFFFFEBCD),
            Color(0xFFD4C5B0),
          ],
        );

        final paint = Paint()
          ..shader = dripGradient.createShader(
            Rect.fromCenter(
              center: Offset(dripX + wiggle, centerY + dripHeight / 2),
              width: 6,
              height: dripHeight,
            ),
          );

        // Teardrop shape
        final dripPath = Path();
        dripPath.moveTo(dripX + wiggle, centerY);
        dripPath.quadraticBezierTo(
          dripX + wiggle - 3,
          centerY + dripHeight * 0.3,
          dripX + wiggle,
          centerY + dripHeight,
        );
        dripPath.quadraticBezierTo(
          dripX + wiggle + 3,
          centerY + dripHeight * 0.3,
          dripX + wiggle,
          centerY,
        );
        dripPath.close();

        canvas.drawPath(dripPath, paint);

        // Highlight on drip
        final highlightPaint = Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..strokeWidth = 1;

        canvas.drawLine(
          Offset(dripX + wiggle - 1, centerY),
          Offset(dripX + wiggle - 1, centerY + dripHeight * 0.7),
          highlightPaint,
        );
      }
    }
  }

  void _drawWick(Canvas canvas, double centerX, double centerY, Size size) {
    final maxCandleHeight = size.height * 0.7;
    final candleHeight = maxCandleHeight * (1 - progress);
    final wickX = centerX;
    final wickTopY = centerY - candleHeight;

    // Charred wick effect
    final wickGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        Color(0xFF654321),
        Color(0xFF2C2C2C),
        Color(0xFF1A1A1A),
      ],
    );

    final wickPaint = Paint()
      ..shader = wickGradient.createShader(
        Rect.fromPoints(
          Offset(wickX, wickTopY),
          Offset(wickX, wickTopY - 14),
        ),
      )
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(wickX, wickTopY + 2),
      Offset(wickX + 0.5, wickTopY - 12),
      wickPaint,
    );

    // Glowing ember at wick tip
    final emberPaint = Paint()
      ..color = Color(0xFFFF4500).withOpacity(0.8)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(Offset(wickX + 0.5, wickTopY - 12), 2, emberPaint);
  }

  void _drawFlame(Canvas canvas, double centerX, double centerY, Size size) {
    final maxCandleHeight = size.height * 0.7;
    final candleHeight = maxCandleHeight * (1 - progress);
    final wickTopY = centerY - candleHeight;
    final flameBaseY = wickTopY - 12;

    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    // Complex flame animations
    final horizontalSway = 4 * math.sin(time * 2 * math.pi / 0.6);
    final verticalBob = 3 * math.sin(time * 2 * math.pi / 0.4 + math.pi / 4);
    final scale = 1.0 + 0.08 * math.sin(time * 2 * math.pi / 0.5);
    final stretch = 1.0 + 0.1 * math.sin(time * 2 * math.pi / 0.35);

    final flameX = centerX + horizontalSway;
    final flameY = flameBaseY - 22 + verticalBob;
    final flameWidth = 28 * scale;
    final flameHeight = 45 * scale * stretch;

    // Outer flame glow (larger, softer)
    final outerGlowGradient = RadialGradient(
      colors: [
        Color(0xFFFFE082).withOpacity(0.6),
        Color(0xFFFF9800).withOpacity(0.3),
        Color(0xFFFF6F00).withOpacity(0.0),
      ],
      stops: [0.0, 0.5, 1.0],
    );

    final outerGlowPaint = Paint()
      ..shader = outerGlowGradient.createShader(
        Rect.fromCenter(
          center: Offset(flameX, flameY),
          width: flameWidth * 2,
          height: flameHeight * 1.5,
        ),
      )
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 25);

    final outerGlowPath = Path();
    outerGlowPath.moveTo(flameX, flameY + flameHeight / 2);
    outerGlowPath.quadraticBezierTo(
      flameX - flameWidth / 2 * 1.2,
      flameY,
      flameX,
      flameY - flameHeight / 2,
    );
    outerGlowPath.quadraticBezierTo(
      flameX + flameWidth / 2 * 1.2,
      flameY,
      flameX,
      flameY + flameHeight / 2,
    );
    outerGlowPath.close();

    canvas.drawPath(outerGlowPath, outerGlowPaint);

    // Main flame body with realistic gradient
    final flameGradient = RadialGradient(
      center: Alignment(0, 0.3),
      colors: [
        Colors.white,
        Color(0xFFFFFDE7),
        Color(0xFFFFE082),
        Color(0xFFFFB74D),
        Color(0xFFFF9800),
        Color(0xFFFF6F00),
      ],
      stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
    );

    final flamePaint = Paint()
      ..shader = flameGradient.createShader(
        Rect.fromCenter(
          center: Offset(flameX, flameY),
          width: flameWidth,
          height: flameHeight,
        ),
      );

    // Enhanced flame shape with more natural curves
    final flamePath = Path();
    flamePath.moveTo(flameX, flameY + flameHeight / 2);
    flamePath.cubicTo(
      flameX - flameWidth / 2,
      flameY + flameHeight / 4,
      flameX - flameWidth / 2.2,
      flameY - flameHeight / 6,
      flameX - flameWidth / 8,
      flameY - flameHeight / 2.5,
    );
    flamePath.quadraticBezierTo(
      flameX,
      flameY - flameHeight / 1.8,
      flameX + flameWidth / 8,
      flameY - flameHeight / 2.5,
    );
    flamePath.cubicTo(
      flameX + flameWidth / 2.2,
      flameY - flameHeight / 6,
      flameX + flameWidth / 2,
      flameY + flameHeight / 4,
      flameX,
      flameY + flameHeight / 2,
    );
    flamePath.close();

    canvas.drawPath(flamePath, flamePaint);

    // Inner white-hot core
    final coreGradient = RadialGradient(
      colors: [
        Colors.white.withOpacity(0.9),
        Color(0xFFFFFDE7).withOpacity(0.7),
        Color(0xFFFFE082).withOpacity(0.0),
      ],
      stops: [0.0, 0.4, 1.0],
    );

    final corePaint = Paint()
      ..shader = coreGradient.createShader(
        Rect.fromCenter(
          center: Offset(flameX, flameY + flameHeight * 0.1),
          width: flameWidth * 0.4,
          height: flameHeight * 0.5,
        ),
      )
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(flameX, flameY + flameHeight * 0.1),
        width: flameWidth * 0.4,
        height: flameHeight * 0.5,
      ),
      corePaint,
    );

    // Flame edge shimmer
    final shimmerPaint = Paint()
      ..color = Color(0xFFFFE082).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawPath(flamePath, shimmerPaint);
  }

  void _drawHeatDistortion(Canvas canvas, double centerX, double centerY, Size size) {
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final maxCandleHeight = size.height * 0.7;
    final candleHeight = maxCandleHeight * (1 - progress);
    final wickTopY = centerY - candleHeight;
    final flameY = wickTopY - 32;

    // Heat wave effect above flame
    for (int i = 0; i < 3; i++) {
      final waveY = flameY - 50 - (i * 20);
      final wavePhase = (time * 2 + i * 0.5) % 2;
      final opacity = 0.15 * (1 - wavePhase / 2);

      final wavePaint = Paint()
        ..color = Color(0xFFFFE082).withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

      final wavePath = Path();
      wavePath.moveTo(centerX - 30, waveY);
      
      for (double x = -30; x <= 30; x += 2) {
        final y = waveY + 5 * math.sin((x / 10) + time * 3 + i);
        wavePath.lineTo(centerX + x, y);
      }

      canvas.drawPath(wavePath, wavePaint);
    }
  }

  void _drawEmbers(Canvas canvas, double centerX, double centerY, Size size) {
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final maxCandleHeight = size.height * 0.7;
    final candleHeight = maxCandleHeight * (1 - progress);
    final wickTopY = centerY - candleHeight;
    final flameBaseY = wickTopY - 12;

    final random = math.Random(42);
    final emberCount = 8;

    for (int i = 0; i < emberCount; i++) {
      final emberTime = time + (i * 0.5);
      final emberPhase = (emberTime % 4) / 4;

      if (emberPhase < 1.0) {
        final horizontalDrift = (random.nextDouble() - 0.5) * 60;
        final emberX = centerX + horizontalDrift * emberPhase;
        final emberY = flameBaseY - (emberPhase * 120);
        final emberOpacity = (1.0 - emberPhase) * (0.6 + 0.4 * math.sin(time * 5 + i));
        final emberSize = 2.5 - (emberPhase * 1.5);

        // Ember glow
        final glowPaint = Paint()
          ..color = Color(0xFFFF6F00).withOpacity(emberOpacity * 0.6)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6);

        canvas.drawCircle(Offset(emberX, emberY), emberSize * 2, glowPaint);

        // Ember core
        final emberPaint = Paint()
          ..color = Color(0xFFFFE082).withOpacity(emberOpacity);

        canvas.drawCircle(Offset(emberX, emberY), emberSize, emberPaint);

        // Ember trail
        if (emberPhase > 0.1) {
          final trailPaint = Paint()
            ..color = Color(0xFFFF9800).withOpacity(emberOpacity * 0.3)
            ..strokeWidth = 1
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);

          canvas.drawLine(
            Offset(emberX, emberY),
            Offset(emberX - horizontalDrift * 0.1, emberY + 10),
            trailPaint,
          );
        }
      }
    }
  }

  void _drawSmoke(Canvas canvas, double centerX, double centerY, Size size) {
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final maxCandleHeight = size.height * 0.7;
    final candleHeight = maxCandleHeight * (1 - progress);
    final wickTopY = centerY - candleHeight;
    final smokeStartY = wickTopY - 55;

    final smokeWisps = 4;

    for (int i = 0; i < smokeWisps; i++) {
      final wispTime = time + (i * 0.8);
      final wispPhase = (wispTime % 5) / 5;

      if (wispPhase < 1.0) {
        final wispY = smokeStartY - (wispPhase * 100);
        final wispX = centerX + 20 * math.sin(wispPhase * math.pi * 2 + i);
        final wispOpacity = (1.0 - wispPhase) * 0.25;
        final wispSize = 8 + (wispPhase * 25);

        final smokePaint = Paint()
          ..color = Color(0xFF9E9E9E).withOpacity(wispOpacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 + wispPhase * 10);

        canvas.drawCircle(Offset(wispX, wispY), wispSize, smokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(CandlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}