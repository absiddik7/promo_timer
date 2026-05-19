import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../providers/candle_simulation_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PAINTS & PATHS
// ─────────────────────────────────────────────────────────────────────────────

final Paint wickPaint = Paint()
  ..color = Colors.white
  ..strokeWidth = 6.8
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.stroke;

final Paint smokePaint = Paint()
  ..color = const Color(0x12AAAAAA)
  ..style = PaintingStyle.fill;

final Paint sparkPaint = Paint()..style = PaintingStyle.fill;

final Path flamePath = Path();
final Path corePath = Path();
final Path innerPath = Path();

// ─────────────────────────────────────────────────────────────────────────────
//  HELPER FUNCTIONS
// ─────────────────────────────────────────────────────────────────────────────

Color blend(Color color, Color target, double amount) {
  return Color.lerp(color, target, amount) ?? color;
}

/// Perlin-like noise function for organic flame movement
double n(double x, double t) =>
    sin(x * 2.1 + t * 2.0) * 0.4 +
    sin(x * 3.7 + t * 2.7) * 0.25 +
    sin(x * 1.3 + t * 1.2) * 0.35;

/// Linear interpolation between two values
double lerp(double a, double b, double t) => a + (b - a) * t;

void drawBackground(
  Canvas canvas,
  double kW,
  double kH,
  Color backgroundInnerColor,
  Color backgroundOuterColor,
) {
  final paint = Paint()
    ..shader = RadialGradient(
      center: const Alignment(0, -0.2),
      radius: 0.9,
      colors: [backgroundInnerColor, backgroundOuterColor],
    ).createShader(Rect.fromLTWH(0, 0, kW, kH));
  canvas.drawRect(Rect.fromLTWH(0, 0, kW, kH), paint);
}

// ─────────────────────────────────────────────────────────────────────────────
//  DRAWING FUNCTIONS
// ─────────────────────────────────────────────────────────────────────────────

void drawCandleBody(Canvas canvas, CandleState s, Color candleBodyColor) {
  final topY = s.candleTopY;
  final currentH = s.currentH;
  final cx = kCX - kCandleW / 2;

  // ── 1. Wax pool puddle at base ─────────────────────────────────────────────
  if (s.melt > 0.05) {
    final pW = kCandleW * (1 + s.melt * 0.35);
    final pH = 6 + s.melt * 11;
    final center = Offset(kCX, kBaseY);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0xFFF0E0B8),
          Color(0xFFE0D0A8),
          Colors.transparent,
        ],
        stops: const [0, 0.6, 1],
      ).createShader(
        Rect.fromCenter(center: center, width: pW, height: pH * 2),
      );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: pW, height: pH),
      paint,
    );

    // Glossy sheen on the wax pool
    final glossW = pW * 0.38;
    final glossH = pH * 0.55;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(kCX - pW * 0.12, kBaseY - pH * 0.18),
        width: glossW,
        height: glossH,
      ),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withAlpha((s.melt * 90).toInt()),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCenter(
            center: Offset(kCX - pW * 0.12, kBaseY - pH * 0.18),
            width: glossW,
            height: glossH,
          ),
        ),
    );
  }

  // ── 2. Candle cylinder body ────────────────────────────────────────────────
  final bodyPath = Path();
  const int sideSteps = 24;

  bodyPath.moveTo(cx, kBaseY);
  for (int i = 0; i <= sideSteps; i++) {
    final t = i / sideSteps;
    final yPos = kBaseY - currentH * t;
    final deformStrength = pow(t, 2.4) * s.melt * 1.6;
    final sideWave =
        sin(t * 2.7 + s.noiseSeed * 0.42) * 0.55 +
        sin(t * 5.1 + s.noiseSeed * 0.19) * 0.28;
    final wobble = sideWave * deformStrength;
    bodyPath.lineTo(cx + wobble, yPos);
  }

  const int topSteps = CandleState.kMeshColumns;
  for (int i = 0; i <= topSteps; i++) {
    final nx = (i / topSteps) * 2.0 - 1.0;
    final xPos = kCX + nx * kCandleW / 2;
    bodyPath.lineTo(xPos, s.surfaceYAtX(xPos));
  }

  for (int i = sideSteps; i >= 0; i--) {
    final t = i / sideSteps;
    final yPos = kBaseY - currentH * t;
    final deformStrength = pow(t, 2.4) * s.melt * 1.6;
    final sideWave =
        sin(t * 2.9 + s.noiseSeed * 0.38 + 1.1) * 0.55 +
        sin(t * 5.4 + s.noiseSeed * 0.16 + 0.7) * 0.28;
    final wobble = sideWave * deformStrength;
    bodyPath.lineTo(cx + kCandleW - wobble, yPos);
  }

  bodyPath.close();

  canvas.drawPath(
    bodyPath,
    Paint()
      ..shader = LinearGradient(
        colors: [
          blend(candleBodyColor, Colors.black, 0.18),
          blend(candleBodyColor, Colors.white, 0.38),
          blend(candleBodyColor, Colors.white, 0.22),
          blend(candleBodyColor, Colors.black, 0.34),
        ],
        stops: const [0, 0.25, 0.7, 1],
      ).createShader(Rect.fromLTWH(cx, topY, kCandleW, currentH)),
  );

  // Vertical highlight strip
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(cx + 7, topY + 5, 11, currentH - 16),
      const Radius.circular(5),
    ),
    Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withAlpha(82), Colors.transparent],
      ).createShader(Rect.fromLTWH(cx + 7, topY, 11, currentH)),
  );

  // ── 3. Glossy / matte surface variation ────────────────────────────────────
  if (s.melt > 0.08) {
    final glossHeight = currentH * s.melt * 0.55;
    canvas.drawRect(
      Rect.fromLTWH(cx + 2, topY, kCandleW - 4, glossHeight),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withAlpha((s.melt * 55).toInt()),
            Colors.white.withAlpha(0),
          ],
        ).createShader(Rect.fromLTWH(cx + 2, topY, kCandleW - 4, glossHeight))
        ..blendMode = BlendMode.overlay,
    );
  }

  drawWaxDrops(canvas, s, candleBodyColor);

  // ── 4. Deformed top surface ──────────────────────────────────────────────
  if (s.melt > 0.0) {
    final topPath = Path();
    bool started = false;
    for (int i = 0; i <= topSteps; i++) {
      final nx = (i / topSteps) * 2.0 - 1.0;
      final xPos = kCX + nx * kCandleW / 2;
      if (!started) {
        topPath.moveTo(xPos, s.surfaceYAtX(xPos));
        started = true;
      } else {
        topPath.lineTo(xPos, s.surfaceYAtX(xPos));
      }
    }
    topPath.close();

    final poolColor = Color.lerp(
      blend(candleBodyColor, Colors.white, 0.45),
      const Color(0xFFFFE4A0),
      s.melt,
    )!;

    canvas.drawPath(
      topPath,
      Paint()
        ..shader = RadialGradient(
          colors: [
            blend(poolColor, Colors.white, 0.45),
            blend(poolColor, Colors.white, 0.25),
            blend(poolColor, Colors.black, 0.15),
          ],
          stops: const [0, 0.6, 1],
        ).createShader(
          Rect.fromCircle(center: Offset(kCX, topY), radius: kCandleW / 2),
        ),
    );

    // Melt pool ripple highlight
    if (s.melt > 0.1) {
      final ripplePath = Path();
      bool rippleStarted = false;
      for (int i = 0; i <= topSteps; i++) {
        final nx = (i / topSteps) * 2.0 - 1.0;
        final xPos = kCX + nx * kCandleW / 2;
        final baseY = s.surfaceYAtX(xPos);
        final ripple = meltRippleNoise(nx, s.time) * s.melt * 2.2;
        final yPos = baseY + ripple;
        if (!rippleStarted) {
          ripplePath.moveTo(xPos, yPos);
          rippleStarted = true;
        } else {
          ripplePath.lineTo(xPos, yPos);
        }
      }
      ripplePath.close();

      canvas.drawPath(
        ripplePath,
        Paint()
          ..color = Colors.white.withAlpha((s.melt * 38).toInt())
          ..blendMode = BlendMode.overlay,
      );
    }

    // Wax dip
    final dipD = min(s.melt * 12, 9.0);
    if (dipD > 0) {
      final poolR = min(kCandleW / 2 - 2, 6 + s.melt * 16);
      final topCenter = Offset(kCX, topY);
      canvas.drawOval(
        Rect.fromCenter(center: topCenter, width: poolR * 2, height: dipD * 2),
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xD9FFFFFF),
              const Color(0xA6F0DCA0),
              Colors.transparent,
            ],
            stops: const [0, 0.6, 1],
          ).createShader(
            Rect.fromCenter(
              center: topCenter,
              width: poolR * 2,
              height: dipD * 2,
            ),
          ),
      );
    }
  }

  // ── 5. Wick ─────────────────────────────────────────────────────────────────
  canvas.drawLine(
    Offset(kCX, topY),
    Offset(kCX + 0.8, topY - s.wickLen),
    wickPaint,
  );
}

void drawWaxDrops(Canvas canvas, CandleState s, Color candleBodyColor) {
  if (s.melt < 0.03 || s.waxDrops.isEmpty) return;

  final baseWax = blend(candleBodyColor, Colors.white, 0.42);
  final waxShadow = blend(candleBodyColor, Colors.black, 0.12);

  for (final drop in s.waxDrops) {
    final candleTopLimitY = s.candleTopY + 0.8;
    final candleBottomY = kBaseY - 1.5;
    final startX = kCX + drop.anchorNx * kCandleW / 2;
    final startY = s.surfaceYAtX(startX);
    final slide = drop.slide;
    final swing = sin(s.time * 2.4 + drop.seed) * 0.9;
    final inward = drop.onLeft ? 1.0 : -1.0;
    final x = startX + swing * 0.22 + inward * min(slide * 0.05, 1.6);
    final connectorH = min(6.0 + slide * 0.24, 18.0);
    final bodyWidth =
        kCandleW * (0.043 + drop.size * 0.011) + drop.stretch * 0.035;
    final bodyHeight = 12.0 + drop.stretch * 1.25;
    final tailHeight = 8.0 + slide * 0.95;
    final opacity = (0.44 + drop.opacity * 0.72).clamp(0.0, 1.0);

    final connectorTopY = startY - 1.2;
    final connectorCenterY = connectorTopY + connectorH * 0.5;
    final neckWidth = bodyWidth * 0.22;

    final neckPath = Path()
      ..moveTo(startX - neckWidth * 0.5, connectorTopY)
      ..quadraticBezierTo(
        startX - neckWidth * 0.55,
        connectorCenterY,
        x - neckWidth * 0.34,
        connectorTopY + connectorH,
      )
      ..lineTo(x + neckWidth * 0.34, connectorTopY + connectorH)
      ..quadraticBezierTo(
        startX + neckWidth * 0.55,
        connectorCenterY,
        startX + neckWidth * 0.5,
        connectorTopY,
      )
      ..close();

    canvas.drawPath(
      neckPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            blend(baseWax, Colors.white, 0.14).withOpacity(opacity),
            blend(baseWax, waxShadow, 0.28).withOpacity(opacity),
            waxShadow.withOpacity((opacity * 0.95).clamp(0.0, 1.0)),
          ],
          stops: const [0, 0.48, 1],
        ).createShader(
          Rect.fromLTWH(
            x - neckWidth,
            connectorTopY,
            neckWidth * 2,
            connectorH,
          ),
        ),
    );

    // Small cap
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(startX, startY + 0.2),
        width: bodyWidth * 0.38,
        height: 2.8,
      ),
      Paint()..color = blend(baseWax, Colors.white, 0.05).withOpacity(opacity),
    );

    final rawBubbleCenterY = connectorTopY + connectorH + slide * 0.62;
    final maxBubbleCenterY = candleBottomY - (bodyHeight * 0.26 + tailHeight);
    final minBubbleCenterY = candleTopLimitY + bodyHeight * 0.5 + 0.2;
    final bubbleCenterY = min(
      max(rawBubbleCenterY, minBubbleCenterY),
      maxBubbleCenterY,
    );
    if (bubbleCenterY <= connectorTopY + connectorH * 0.55 ||
        bubbleCenterY - bodyHeight * 0.5 < candleTopLimitY) {
      continue;
    }
    final bubbleCenter = Offset(x, bubbleCenterY);
    final bubblePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          blend(baseWax, Colors.white, 0.10).withOpacity(opacity),
          baseWax.withOpacity(opacity),
          blend(baseWax, waxShadow, 0.34).withOpacity(opacity),
          waxShadow.withOpacity((opacity * 0.96).clamp(0.0, 1.0)),
        ],
        stops: const [0, 0.34, 0.72, 1],
      ).createShader(
        Rect.fromCenter(
          center: bubbleCenter,
          width: bodyWidth,
          height: bodyHeight + tailHeight,
        ),
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: bubbleCenter,
        width: bodyWidth,
        height: bodyHeight,
      ),
      bubblePaint,
    );

    final edgeShadePath = Path()
      ..addOval(
        Rect.fromCenter(
          center: bubbleCenter,
          width: bodyWidth,
          height: bodyHeight,
        ),
      );
    canvas.drawPath(
      edgeShadePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.2, bodyWidth * 0.075)
        ..color = blend(baseWax, waxShadow, 0.55).withOpacity(opacity * 0.62),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          x + (drop.onLeft ? -bodyWidth * 0.1 : bodyWidth * 0.1),
          bubbleCenter.dy - bodyHeight * 0.1,
        ),
        width: bodyWidth * 0.56,
        height: bodyHeight * 0.38,
      ),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity((0.20 * opacity).clamp(0.0, 1.0)),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCenter(
            center: Offset(
              x + (drop.onLeft ? -bodyWidth * 0.1 : bodyWidth * 0.1),
              bubbleCenter.dy - bodyHeight * 0.1,
            ),
            width: bodyWidth * 0.56,
            height: bodyHeight * 0.38,
          ),
        ),
    );

    final bubbleAlpha = (opacity * 1.1).clamp(0.0, 1.0);
    final innerBubbleR = max(1.2, bodyWidth * 0.11);
    final innerBubbleCenterA = Offset(
      x + (drop.onLeft ? bodyWidth * 0.09 : -bodyWidth * 0.09),
      bubbleCenter.dy + bodyHeight * 0.03,
    );
    final innerBubbleCenterB = Offset(
      x + (drop.onLeft ? -bodyWidth * 0.05 : bodyWidth * 0.05),
      bubbleCenter.dy - bodyHeight * 0.08,
    );

    canvas.drawCircle(
      innerBubbleCenterA,
      innerBubbleR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.1, innerBubbleR * 0.52)
        ..color = Colors.white.withOpacity(0.84 * bubbleAlpha),
    );
    canvas.drawCircle(
      innerBubbleCenterA + const Offset(-0.5, -0.5),
      innerBubbleR * 0.45,
      Paint()..color = Colors.white.withOpacity(0.48 * bubbleAlpha),
    );

    canvas.drawCircle(
      innerBubbleCenterB,
      innerBubbleR * 0.8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, innerBubbleR * 0.42)
        ..color = Colors.white.withOpacity(0.72 * bubbleAlpha),
    );
    canvas.drawCircle(
      innerBubbleCenterB + const Offset(-0.35, -0.35),
      innerBubbleR * 0.28,
      Paint()..color = Colors.white.withOpacity(0.40 * bubbleAlpha),
    );

    final allowedTailHeight =
        candleBottomY - (bubbleCenter.dy + bodyHeight * 0.26);
    final tailDrawHeight = min(tailHeight, max(0.0, allowedTailHeight));
    if (tailDrawHeight > 0.1) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(
              x,
              bubbleCenter.dy + bodyHeight * 0.26 + tailDrawHeight * 0.5,
            ),
            width: bodyWidth * 0.28,
            height: tailDrawHeight,
          ),
          Radius.circular(bodyWidth * 0.14),
        ),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              blend(baseWax, Colors.white, 0.12).withOpacity(opacity),
              waxShadow.withOpacity(opacity),
            ],
          ).createShader(
            Rect.fromCenter(
              center: Offset(
                x,
                bubbleCenter.dy + bodyHeight * 0.26 + tailDrawHeight * 0.5,
              ),
              width: bodyWidth * 0.28,
              height: tailDrawHeight,
            ),
          ),
      );
    }
  }
}

void drawAmbientGlow(Canvas canvas, double wickY, CandleState s) {
  final flicker = n(4, s.time) * 0.5 + 0.5;
  final intensity = lerp(0.25, 0.38, flicker) * (1 - s.blownAmt * 0.9);
  final center = Offset(kCX, wickY - 32);
  canvas.drawCircle(
    center,
    220,
    Paint()
      ..shader = RadialGradient(
        colors: [
          Color.fromRGBO(255, 160, 30, intensity),
          Color.fromRGBO(255, 80, 10, intensity * 0.4),
          Colors.transparent,
        ],
        stops: const [0, 0.4, 1],
      ).createShader(Rect.fromCircle(center: center, radius: 220)),
  );
}

void drawHeatDistortion(Canvas canvas, double wickY, CandleState s) {
  if (s.blownAmt > 0.85) return;
  final t = s.time;
  final flicker = n(7, t) * 0.5 + 0.5;
  final baseOpacity = (0.04 + flicker * 0.05) * (1 - s.blownAmt);

  for (int i = 0; i < 5; i++) {
    final phase = i * 1.26;
    final xOff = sin(t * 1.8 + phase) * 3.5;
    final alpha = (baseOpacity * (1 - i * 0.17) * 255).toInt().clamp(0, 255);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(kCX + xOff, wickY - 48 - i * 14.0),
        width: 18.0 - i * 2.0,
        height: 26.0 + i * 3.0,
      ),
      Paint()
        ..color = Color.fromARGB(alpha, 255, 220, 120)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..blendMode = BlendMode.screen,
    );
  }
}

void drawFlame(
  Canvas canvas,
  double wickY,
  CandleState s, {
  double flameScale = 1.0,
  bool isAnimated = true,
}) {
  final t = isAnimated ? s.time : 0.0;
  final endPhase = ((s.melt - 0.8) / 0.2).clamp(0.0, 1.0);
  final endScale = lerp(1.0, 0.55, endPhase);

  final flicker = n(0, t) * 0.5 + 0.5;

  const double baseSway = 10.0;
  const double blowInfluence = 2.3;
  final sway = n(1, t) * baseSway * (1 + s.blownAmt * blowInfluence);

  const double minFlameHeight = 96.0;
  const double maxFlameHeight = 150.0;
  const double blowExtinguishRate = 0.78;
  final h =
      lerp(minFlameHeight, maxFlameHeight, flicker) *
      (1 - s.blownAmt * blowExtinguishRate) *
      endScale *
      flameScale;

  const double minFlameWidth = 21.0;
  const double maxFlameWidth = 30.0;
  const double blowWidthBoost = 0.45;
  final w =
      lerp(minFlameWidth, maxFlameWidth, flicker) *
      (1 + s.blownAmt * blowWidthBoost) *
      endScale *
      flameScale;

  const double baseYOffset = 2.0;
  final baseY = wickY - baseYOffset;
  final tipX = kCX + sway;
  final tipY = wickY - h;

  flamePath
    ..reset()
    ..moveTo(kCX - w * 0.88, baseY - 0.6)
    ..cubicTo(
      kCX - w * 1.18,
      wickY - h * 0.22,
      kCX - w * 1.05 + sway * 0.2 + n(2, t) * 2.5,
      wickY - h * 0.66,
      tipX,
      tipY,
    )
    ..cubicTo(
      kCX + w * 1.08 + sway * 0.34 + n(3, t) * 2.6,
      wickY - h * 0.66,
      kCX + w * 1.16,
      wickY - h * 0.22,
      kCX + w * 0.88,
      baseY - 0.6,
    )
    ..cubicTo(
      kCX + w * 0.58,
      wickY + 5.8,
      kCX + w * 0.2,
      wickY + 2.8,
      kCX,
      wickY + 1.3,
    )
    ..cubicTo(
      kCX - w * 0.2,
      wickY + 2.8,
      kCX - w * 0.58,
      wickY + 5.8,
      kCX - w * 0.88,
      baseY - 0.6,
    )
    ..close();

  canvas.drawPath(
    flamePath,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: const [
          Color(0xFFFFB02B),
          Color(0xFFFF9A1E),
          Color(0xFFFF7A14),
          Color(0xFFF15B0A),
          Color(0x99FFB347),
        ],
        stops: const [0, 0.24, 0.52, 0.8, 1],
      ).createShader(Rect.fromLTWH(kCX - w * 1.2, tipY, w * 2.4, h + 8)),
  );

  corePath
    ..reset()
    ..moveTo(kCX - w * 0.52, wickY - 4.4)
    ..cubicTo(
      kCX - w * 0.62,
      wickY - h * 0.25,
      kCX - w * 0.4 + sway * 0.2,
      wickY - h * 0.56,
      kCX + sway * 0.42,
      tipY + h * 0.14,
    )
    ..cubicTo(
      kCX + w * 0.4 + sway * 0.24,
      wickY - h * 0.56,
      kCX + w * 0.62,
      wickY - h * 0.25,
      kCX + w * 0.52,
      wickY - 4.4,
    )
    ..cubicTo(
      kCX + w * 0.28,
      wickY + 1.8,
      kCX + w * 0.08,
      wickY + 0.9,
      kCX,
      wickY + 0.4,
    )
    ..cubicTo(
      kCX - w * 0.08,
      wickY + 0.9,
      kCX - w * 0.28,
      wickY + 1.8,
      kCX - w * 0.52,
      wickY - 4.4,
    )
    ..close();

  canvas.drawPath(
    corePath,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: const [
          Color(0xFFFFF4AE),
          Color(0xFFFFEB7A),
          Color(0xCCFFD664),
          Color(0x88FFD664),
        ],
        stops: const [0, 0.44, 0.78, 1],
      ).createShader(
        Rect.fromLTWH(kCX - w * 0.65, tipY + h * 0.12, w * 1.3, h * 0.75),
      ),
  );

  innerPath
    ..reset()
    ..moveTo(kCX - w * 0.2, wickY - 6)
    ..cubicTo(
      kCX - w * 0.24,
      wickY - h * 0.28,
      kCX + sway * 0.18,
      wickY - h * 0.48,
      kCX + sway * 0.28,
      tipY + h * 0.29,
    )
    ..cubicTo(
      kCX + sway * 0.18,
      wickY - h * 0.48,
      kCX + w * 0.24,
      wickY - h * 0.28,
      kCX + w * 0.2,
      wickY - 6,
    )
    ..cubicTo(
      kCX + w * 0.1,
      wickY - 0.2,
      kCX + w * 0.03,
      wickY - 0.5,
      kCX,
      wickY - 0.8,
    )
    ..cubicTo(
      kCX - w * 0.03,
      wickY - 0.5,
      kCX - w * 0.1,
      wickY - 0.2,
      kCX - w * 0.2,
      wickY - 6,
    )
    ..close();

  canvas.drawPath(
    innerPath,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: const [
          Color(0xFFFFFFFF),
          Color(0xFFFFF6C5),
          Color(0xE6FFEAA0),
          Color(0x66FFEAA0),
        ],
        stops: const [0, 0.34, 0.72, 1],
      ).createShader(
        Rect.fromLTWH(kCX - w * 0.26, tipY + h * 0.24, w * 0.52, h * 0.58),
      ),
  );

  if (s.blownAmt < 0.8) {
    final rimLightAlpha = ((flicker * 0.55 + 0.1) * (1 - s.blownAmt) * 255)
        .toInt()
        .clamp(0, 130);
    final rimCenter = Offset(kCX + sway * 0.15, s.candleTopY + 2);
    canvas.drawOval(
      Rect.fromCenter(center: rimCenter, width: kCandleW * 0.82, height: 22),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromARGB(rimLightAlpha, 255, 200, 80),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCenter(
            center: rimCenter,
            width: kCandleW * 0.82,
            height: 22,
          ),
        ),
    );
  }

  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(kCX + sway * 0.07, wickY - 1.5),
      width: w * 0.44,
      height: 7.2,
    ),
    Paint()..color = const ui.Color.fromARGB(153, 161, 1, 1),
  );
}

void drawParticles(Canvas canvas, CandleState s) {
  for (final p in s.particles) {
    if (p.isSpark) {
      final hue = 40.0 + p.life * 20.0;
      final lightness = 0.6 + p.life * 0.3;
      sparkPaint.color = HSLColor.fromAHSL(
        p.life * 0.9,
        hue,
        1.0,
        lightness,
      ).toColor();
      canvas.drawCircle(Offset(p.x, p.y), p.size * p.life, sparkPaint);
    } else {
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.size,
        Paint()
          ..color = Color.fromRGBO(170, 170, 170, p.life * 0.07)
          ..style = PaintingStyle.fill,
      );
    }
  }
}

void drawSmokeOnly(Canvas canvas, CandleState s) {
  for (final p in s.particles) {
    if (!p.isSpark) {
      canvas.drawCircle(Offset(p.x, p.y), p.size, smokePaint);
    }
  }
}
