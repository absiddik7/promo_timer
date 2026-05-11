import 'dart:math';

import 'package:flutter/foundation.dart';

// Canvas dimensions used by the candle simulation and painters.
double kW = 390;
double kH = 844;
double kCX = 195;
double kBaseY = 607;
double kCandleW = 86;
double kFullH = 258;

double meltRippleNoise(double x, double t) =>
    sin(x * 5.0 + t * 0.8) * 0.35 +
    sin(x * 11.0 + t * 1.4) * 0.20 +
    sin(x * 17.0 + t * 0.5) * 0.10;

double _surfaceNoise(double x, double seed) =>
    sin(x * 3.14 + seed * 1.7) * 0.42 +
    sin(x * 7.28 + seed * 2.3) * 0.28 +
    sin(x * 12.56 + seed * 0.9) * 0.18 +
    sin(x * 19.63 + seed * 3.1) * 0.12;

class CandleSimulationProvider extends ChangeNotifier {
  final CandleState state = CandleState();

  void tick() {
    state.tick();
  }

  void reset() {
    state.reset();
    notifyListeners();
  }

  void relightIfNeeded() {
    if (!state.blown) return;
    state.relight();
    notifyListeners();
  }

  void setMelt(double melt) {
    if ((melt - state.melt).abs() <= 0.0015) return;
    state.melt = melt;
    state.bodyDirty = true;
  }

  void completeAndBlowOut() {
    state.melt = 1.0;
    state.blowOut();
    state.bodyDirty = true;
    notifyListeners();
  }
}

class CandleState {
  double time = 0;
  double melt = 0;
  bool blown = false;
  double blownAmt = 0;
  int frameCount = 0;
  bool bodyDirty = true;
  final List<Particle> particles = [];
  final Random _rng = Random();

  // Unique seed per candle instance to keep each run slightly different.
  final double noiseSeed = Random().nextDouble() * 100;

  List<double> topProfile = [];
  double _lastProfileMelt = -1;

  CandleState() {
    for (int i = 0; i < 25; i++) {
      final p = Particle(_rng, wickY);
      p.life = _rng.nextDouble();
      particles.add(p);
    }
  }

  double get currentH => kFullH * (1 - melt * 0.94);
  double get candleTopY => kBaseY - currentH;
  double get wickLen => 16.0;
  double get wickY => candleTopY - wickLen;

  static const int kMeshColumns = 32;

  void rebuildTopProfile() {
    _lastProfileMelt = melt;
    topProfile = List.generate(kMeshColumns + 1, (i) {
      final nx = (i / kMeshColumns) * 2.0 - 1.0;
      final rimWeight = 0.35 + 0.65 * pow(nx.abs(), 0.8);
      final noise = _surfaceNoise(nx, noiseSeed);
      final ridges =
          sin(nx * 31.4 + noiseSeed * 0.7) * 0.12 +
          sin(nx * 47.1 + noiseSeed * 1.9) * 0.08;
      final maxDeform = (2.5 + melt * 18.0) * rimWeight;
      return (noise + ridges) * maxDeform;
    });
  }

  double topProfileAt(double nx) {
    if (topProfile.isEmpty) return 0;
    final t = (nx + 1.0) / 2.0 * kMeshColumns;
    final lo = t.floor().clamp(0, kMeshColumns - 1);
    final hi = (lo + 1).clamp(0, kMeshColumns);
    final frac = t - lo;
    final a = topProfile[lo];
    final b = topProfile[hi.clamp(0, topProfile.length - 1)];
    return a + (b - a) * frac;
  }

  double surfaceYAtX(double x) {
    final halfWidth = kCandleW / 2;
    if (halfWidth <= 0) return candleTopY;
    final nx = (((x - kCX) / halfWidth).clamp(-1.0, 1.0)).toDouble();
    final meltLevel = melt.clamp(0.0, 1.0);
    final meltEase = meltLevel == 0.0
        ? 0.0
        : (0.45 + 0.55 * pow(meltLevel, 0.38)).toDouble();
    final centerBias = 1.0 - nx.abs();
    final centerDip = melt * 5.5 * pow(centerBias, 1.45);
    final edgeMix = ((nx.abs() - 0.62) / 0.38).clamp(0.0, 1.0).toDouble();
    final cornerMask = edgeMix * edgeMix * (3 - 2 * edgeMix);
    final earlyRoundStrength = (1.0 - (melt / 0.24).clamp(0.0, 1.0)) * 4.8;
    final cornerRound = cornerMask * earlyRoundStrength;
    final leanDirection = sin(noiseSeed * 0.73) >= 0 ? 1.0 : -1.0;
    final leanSide = ((nx * leanDirection) + 1.0) * 0.5;
    final leanDrop = meltEase * 13.5 * pow(leanSide, 1.14);
    final leanTilt = meltEase * 5.2 * nx * leanDirection;
    return candleTopY +
        topProfileAt(nx) +
        centerDip +
        cornerRound +
        leanDrop +
        leanTilt;
  }

  void tick() {
    frameCount++;
    const double timeStep = 0.022;
    time += timeStep;

    const double blowInRate = 0.04;
    const double blowOutRate = 0.02;
    if (blown) {
      blownAmt = min(1.0, blownAmt + blowInRate);
    } else {
      blownAmt = max(0.0, blownAmt - blowOutRate);
    }

    if ((melt - _lastProfileMelt).abs() > 0.005 || topProfile.isEmpty) {
      rebuildTopProfile();
    }

    final wy = wickY;
    for (final p in particles) {
      p.update(_rng, wy);
    }
  }

  void blowOut() {
    blown = true;
    bodyDirty = true;
  }

  void relight() {
    blown = false;
    blownAmt = 0;
    bodyDirty = true;
  }

  void reset() {
    melt = 0;
    blown = false;
    blownAmt = 0;
    frameCount = 0;
    topProfile.clear();
    _lastProfileMelt = -1;
    bodyDirty = true;
  }
}

class Particle {
  double x, y, vx, vy, life, decay, size;
  bool isSpark;
  final Random _rng;

  Particle(this._rng, double wickY)
    : x = kCX,
      y = wickY,
      vx = 0,
      vy = 0,
      life = 1,
      decay = 0.015,
      size = 2,
      isSpark = true {
    _reset(wickY);
  }

  void _reset(double wickY) {
    const double horizontalSpread = 8.0;
    x = kCX + _rng.nextDouble() * horizontalSpread - horizontalSpread / 2;

    const double verticalSpread = 12.0;
    const double verticalOffset = 4.0;
    y = wickY - _rng.nextDouble() * verticalSpread - verticalOffset;

    const double maxHorizontalVelocity = 1.3;
    vx = _rng.nextDouble() * maxHorizontalVelocity - maxHorizontalVelocity / 2;

    const double minVerticalVelocity = 1.3;
    const double maxVerticalVariance = 1.5;
    vy = -(_rng.nextDouble() * maxVerticalVariance + minVerticalVelocity);

    life = 1;

    const double decayBase = 0.013;
    const double decayVariance = 0.015;
    decay = _rng.nextDouble() * decayVariance + decayBase;

    const double minSize = 1.6;
    const double sizeVariance = 1.6;
    size = _rng.nextDouble() * sizeVariance + minSize;

    const double sparkProbability = 0.62;
    isSpark = _rng.nextDouble() < sparkProbability;
  }

  void update(Random rng, double wickY) {
    const double turbulenceAmount = 0.45;
    x += vx + rng.nextDouble() * turbulenceAmount - turbulenceAmount / 2;
    y += vy;

    const double verticalDrag = 0.975;
    vy *= verticalDrag;

    life -= decay;

    if (!isSpark) {
      const double smokeGrowthRate = 1.022;
      size *= smokeGrowthRate;
      const double smokeDrag = 0.965;
      vx *= smokeDrag;
    }

    if (life <= 0) _reset(wickY);
  }
}
