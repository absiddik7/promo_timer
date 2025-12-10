import 'package:flutter/material.dart';
import 'dart:math' as math;

class CandlePainter extends CustomPainter {
  final double progress;
  final Animation<double>? flameAnimation;

  CandlePainter({
    required this.progress,
    this.flameAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.6;

    _drawCandleStand(canvas, centerX, centerY, size);
    _drawCandleBody(canvas, centerX, centerY, size);
    _drawWaxPool(canvas, centerX, centerY, size);
    _drawWaxDrips(canvas, centerX, centerY, size);
    _drawWick(canvas, centerX, centerY, size);
    _drawBackgroundGlow(canvas, centerX, centerY, size);
    _drawLightRays(canvas, centerX, centerY, size);
    _drawFlame(canvas, centerX, centerY, size);
    _drawHeatDistortion(canvas, centerX, centerY, size);
    _drawEmbers(canvas, centerX, centerY, size);
    _drawSmoke(canvas, centerX, centerY, size);
  }

  double _smoothStep(double t) {
    return t * t * (3.0 - 2.0 * t);
  }

  void _drawCandleStand(Canvas canvas, double centerX, double centerY, Size size) {
    final standWidth = size.width * 0.25;
    final standHeight = size.height * 0.15;
    final standTop = centerY + 5;

    final baseGradient = RadialGradient(
      colors: [Color(0xFFB8860B), Color(0xFFDAA520), Color(0xFF8B7355)],
      stops: [0.0, 0.6, 1.0],
    );

    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, standTop + standHeight - 8), width: standWidth * 1.2, height: 16),
      Paint()..shader = baseGradient.createShader(Rect.fromCenter(center: Offset(centerX, standTop + standHeight - 8), width: standWidth * 1.2, height: 16)),
    );

    final stemGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF8B7355), Color(0xFFDAA520), Color(0xFFFFD700), Color(0xFFDAA520), Color(0xFF8B7355)],
      stops: [0.0, 0.3, 0.5, 0.7, 1.0],
    );

    final stemPath = Path()
      ..moveTo(centerX - standWidth * 0.15, standTop + 15)
      ..lineTo(centerX - standWidth * 0.12, standTop + standHeight - 20)
      ..lineTo(centerX + standWidth * 0.12, standTop + standHeight - 20)
      ..lineTo(centerX + standWidth * 0.15, standTop + 15)
      ..close();

    canvas.drawPath(stemPath, Paint()..shader = stemGradient.createShader(Rect.fromLTWH(centerX - standWidth * 0.15, standTop + 15, standWidth * 0.3, standHeight - 30)));

    final holderPath = Path()
      ..moveTo(centerX - standWidth * 0.2, standTop + 15)
      ..lineTo(centerX - standWidth * 0.25, standTop)
      ..lineTo(centerX + standWidth * 0.25, standTop)
      ..lineTo(centerX + standWidth * 0.2, standTop + 15)
      ..close();

    canvas.drawPath(holderPath, Paint()..color = Color(0xFFB8860B));

    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, standTop), width: standWidth * 0.5, height: 8),
      Paint()..color = Color(0xFFDAA520),
    );

    canvas.drawLine(
      Offset(centerX - standWidth * 0.13, standTop + 17),
      Offset(centerX - standWidth * 0.11, standTop + standHeight - 22),
      Paint()
        ..color = Color(0xFFFFD700).withOpacity(0.7)
        ..strokeWidth = 1.5
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1),
    );
  }

  void _drawBackgroundGlow(Canvas canvas, double centerX, double centerY, Size size) {
    final maxCandleHeight = size.height * 0.7;
    final smoothProgress = _smoothStep(progress);
    final candleHeight = maxCandleHeight * (1 - smoothProgress);
    final wickTopY = centerY - candleHeight;
    final flameY = wickTopY - 32;

    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final glowPulse = 1.0 + 0.12 * math.sin(time * 1.5);
    final glowRadius = 140 * glowPulse;

    final glows = [
      (radius: glowRadius * 0.3, opacity: 0.7, colors: [Color(0xFFFFE082), Color(0xFFFFB74D)]),
      (radius: glowRadius * 0.6, opacity: 0.4, colors: [Color(0xFFFFB74D), Color(0xFFFF9800)]),
      (radius: glowRadius * 1.0, opacity: 0.2, colors: [Color(0xFFFF9800), Color(0xFFFF6F00)]),
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

      canvas.drawCircle(
        Offset(centerX, flameY),
        glow.radius,
        Paint()
          ..shader = gradient.createShader(Rect.fromCircle(center: Offset(centerX, flameY), radius: glow.radius))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
  }

  void _drawLightRays(Canvas canvas, double centerX, double centerY, Size size) {
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final maxCandleHeight = size.height * 0.7;
    final smoothProgress = _smoothStep(progress);
    final candleHeight = maxCandleHeight * (1 - smoothProgress);
    final wickTopY = centerY - candleHeight;
    final flameY = wickTopY - 32;

    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi + time * 0.4;
      final rayLength = 55 + 18 * math.sin(time * 1.8 + i);
      final opacity = 0.12 + 0.06 * math.sin(time * 2.2 + i);

      canvas.drawLine(
        Offset(centerX + math.cos(angle) * 12, flameY + math.sin(angle) * 12),
        Offset(centerX + math.cos(angle) * rayLength, flameY + math.sin(angle) * rayLength),
        Paint()
          ..shader = LinearGradient(
            colors: [Color(0xFFFFE082).withOpacity(opacity), Color(0xFFFFE082).withOpacity(0.0)],
          ).createShader(Rect.fromPoints(
            Offset(centerX + math.cos(angle) * 12, flameY + math.sin(angle) * 12),
            Offset(centerX + math.cos(angle) * rayLength, flameY + math.sin(angle) * rayLength),
          ))
          ..strokeWidth = 2
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  void _drawCandleBody(Canvas canvas, double centerX, double centerY, Size size) {
    final candleWidth = size.width * 0.15;
    final maxCandleHeight = size.height * 0.7;
    final smoothProgress = _smoothStep(progress);
    final candleHeight = maxCandleHeight * (1 - smoothProgress);

    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFE8D5C4), Color(0xFFFFF8DC), Color(0xFFFFEBCD), Color(0xFFFFF8DC), Color(0xFFD4C5B0)],
      stops: [0.0, 0.2, 0.5, 0.8, 1.0],
    );

    final path = Path()
      ..moveTo(centerX - candleWidth / 2, centerY - candleHeight)
      ..lineTo(centerX + candleWidth / 2, centerY - candleHeight)
      ..lineTo(centerX + candleWidth / 2 * 0.92, centerY)
      ..lineTo(centerX - candleWidth / 2 * 0.92, centerY)
      ..close();

    canvas.drawPath(path, Paint()..shader = gradient.createShader(Rect.fromLTWH(centerX - candleWidth / 2, centerY - candleHeight, candleWidth, candleHeight)));

    canvas.drawLine(
      Offset(centerX - candleWidth / 2 + 1, centerY - candleHeight),
      Offset(centerX - candleWidth / 2 * 0.92 + 1, centerY),
      Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..strokeWidth = 1.5
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1),
    );

    canvas.drawLine(
      Offset(centerX + candleWidth / 2 - 1, centerY - candleHeight),
      Offset(centerX + candleWidth / 2 * 0.92 - 1, centerY),
      Paint()
        ..color = Color(0xFF8B7355).withOpacity(0.4)
        ..strokeWidth = 3
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  void _drawWaxPool(Canvas canvas, double centerX, double centerY, Size size) {
    final candleWidth = size.width * 0.15;
    final maxCandleHeight = size.height * 0.7;
    final smoothProgress = _smoothStep(progress);
    final candleHeight = maxCandleHeight * (1 - smoothProgress);
    final poolY = centerY - candleHeight;
    final poolDepth = 8 + smoothProgress * 5;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, poolY + poolDepth / 2), width: candleWidth * 0.9, height: poolDepth),
      Paint()
        ..shader = RadialGradient(
          colors: [Color(0xFFFFE082).withOpacity(0.8), Color(0xFFFFD54F).withOpacity(0.6), Color(0xFFFFEBCD).withOpacity(0.3)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCenter(center: Offset(centerX, poolY + poolDepth / 2), width: candleWidth * 0.9, height: poolDepth)),
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
        final dripHeight = 35 * math.min(localProgress, 1.0);
        final wiggle = 2 * math.sin(time * 0.8 + i);

        final dripPath = Path()
          ..moveTo(dripX + wiggle, centerY)
          ..quadraticBezierTo(dripX + wiggle - 3, centerY + dripHeight * 0.3, dripX + wiggle, centerY + dripHeight)
          ..quadraticBezierTo(dripX + wiggle + 3, centerY + dripHeight * 0.3, dripX + wiggle, centerY)
          ..close();

        canvas.drawPath(dripPath, Paint()..color = Color(0xFFFFEBCD));
      }
    }
  }

  void _drawWick(Canvas canvas, double centerX, double centerY, Size size) {
    final maxCandleHeight = size.height * 0.7;
    final smoothProgress = _smoothStep(progress);
    final candleHeight = maxCandleHeight * (1 - smoothProgress);
    final wickTopY = centerY - candleHeight;

    canvas.drawLine(
      Offset(centerX, wickTopY + 2),
      Offset(centerX + 0.5, wickTopY - 12),
      Paint()
        ..color = Color(0xFF2C2C2C)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    canvas.drawCircle(
      Offset(centerX + 0.5, wickTopY - 12),
      2,
      Paint()
        ..color = Color(0xFFFF4500).withOpacity(0.7 + 0.3 * math.sin(time * 2.5))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _drawFlame(Canvas canvas, double centerX, double centerY, Size size) {
    final maxCandleHeight = size.height * 0.7;
    final smoothProgress = _smoothStep(progress);
    final candleHeight = maxCandleHeight * (1 - smoothProgress);
    final wickTopY = centerY - candleHeight;
    final flameBaseY = wickTopY - 12;

    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final horizontalSway = 3.5 * math.sin(time * 1.2);
    final verticalBob = 2.5 * math.sin(time * 0.9 + math.pi / 4);
    final scale = 1.0 + 0.06 * math.sin(time * 1.5);
    final stretch = 1.0 + 0.08 * math.sin(time * 1.1);

    final flameX = centerX + horizontalSway;
    final flameY = flameBaseY - 22 + verticalBob;
    final flameWidth = 28 * scale;
    final flameHeight = 45 * scale * stretch;

    final flamePath = Path()
      ..moveTo(flameX, flameY + flameHeight / 2)
      ..cubicTo(flameX - flameWidth / 2, flameY + flameHeight / 4, flameX - flameWidth / 2.2, flameY - flameHeight / 6, flameX - flameWidth / 8, flameY - flameHeight / 2.5)
      ..quadraticBezierTo(flameX, flameY - flameHeight / 1.8, flameX + flameWidth / 8, flameY - flameHeight / 2.5)
      ..cubicTo(flameX + flameWidth / 2.2, flameY - flameHeight / 6, flameX + flameWidth / 2, flameY + flameHeight / 4, flameX, flameY + flameHeight / 2)
      ..close();

    canvas.drawPath(
      flamePath,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(0, 0.3),
          colors: [Colors.white, Color(0xFFFFFDE7), Color(0xFFFFE082), Color(0xFFFFB74D), Color(0xFFFF9800), Color(0xFFFF6F00)],
          stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
        ).createShader(Rect.fromCenter(center: Offset(flameX, flameY), width: flameWidth, height: flameHeight)),
    );

    canvas.drawOval(
      Rect.fromCenter(center: Offset(flameX, flameY + flameHeight * 0.1), width: flameWidth * 0.4, height: flameHeight * 0.5),
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withOpacity(0.9), Color(0xFFFFFDE7).withOpacity(0.7), Color(0xFFFFE082).withOpacity(0.0)],
          stops: [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCenter(center: Offset(flameX, flameY + flameHeight * 0.1), width: flameWidth * 0.4, height: flameHeight * 0.5))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  void _drawHeatDistortion(Canvas canvas, double centerX, double centerY, Size size) {
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final maxCandleHeight = size.height * 0.7;
    final smoothProgress = _smoothStep(progress);
    final candleHeight = maxCandleHeight * (1 - smoothProgress);
    final wickTopY = centerY - candleHeight;
    final flameY = wickTopY - 32;

    for (int i = 0; i < 3; i++) {
      final waveY = flameY - 50 - (i * 20);
      final wavePhase = (time * 1.5 + i * 0.5) % 2;
      final opacity = 0.15 * (1 - wavePhase / 2);

      final wavePath = Path()..moveTo(centerX - 30, waveY);
      for (double x = -30; x <= 30; x += 2) {
        wavePath.lineTo(centerX + x, waveY + 5 * math.sin((x / 10) + time * 3 + i));
      }

      canvas.drawPath(
        wavePath,
        Paint()
          ..color = Color(0xFFFFE082).withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  void _drawEmbers(Canvas canvas, double centerX, double centerY, Size size) {
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final maxCandleHeight = size.height * 0.7;
    final smoothProgress = _smoothStep(progress);
    final candleHeight = maxCandleHeight * (1 - smoothProgress);
    final wickTopY = centerY - candleHeight;
    final flameBaseY = wickTopY - 12;
    final random = math.Random(42);

    for (int i = 0; i < 8; i++) {
      final emberTime = time + (i * 0.5);
      final emberPhase = (emberTime % 4) / 4;

      if (emberPhase < 1.0) {
        final horizontalDrift = (random.nextDouble() - 0.5) * 60;
        final emberX = centerX + horizontalDrift * emberPhase;
        final emberY = flameBaseY - (emberPhase * 120);
        final emberOpacity = (1.0 - emberPhase) * (0.6 + 0.4 * math.sin(time * 5 + i));
        final emberSize = 2.5 - (emberPhase * 1.5);

        canvas.drawCircle(Offset(emberX, emberY), emberSize * 2, Paint()..color = Color(0xFFFF6F00).withOpacity(emberOpacity * 0.6)..maskFilter = MaskFilter.blur(BlurStyle.normal, 6));
        canvas.drawCircle(Offset(emberX, emberY), emberSize, Paint()..color = Color(0xFFFFE082).withOpacity(emberOpacity));
      }
    }
  }

  void _drawSmoke(Canvas canvas, double centerX, double centerY, Size size) {
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final maxCandleHeight = size.height * 0.7;
    final smoothProgress = _smoothStep(progress);
    final candleHeight = maxCandleHeight * (1 - smoothProgress);
    final wickTopY = centerY - candleHeight;
    final smokeStartY = wickTopY - 55;

    for (int i = 0; i < 4; i++) {
      final wispTime = time + (i * 0.8);
      final wispPhase = (wispTime % 5) / 5;

      if (wispPhase < 1.0) {
        final wispY = smokeStartY - (wispPhase * 100);
        final wispX = centerX + 20 * math.sin(wispPhase * math.pi * 2 + i);
        final wispOpacity = (1.0 - wispPhase) * 0.25;
        final wispSize = 8 + (wispPhase * 25);

        canvas.drawCircle(
          Offset(wispX, wispY),
          wispSize,
          Paint()
            ..color = Color(0xFF9E9E9E).withOpacity(wispOpacity)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 + wispPhase * 10),
        );
      }
    }
  }

  @override
  bool shouldRepaint(CandlePainter oldDelegate) => oldDelegate.progress != progress;
}