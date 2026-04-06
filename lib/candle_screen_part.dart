part of 'main.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CONSTANTS  — mutable so _CandleScreenState can resize them to fill screen
// ─────────────────────────────────────────────────────────────────────────────
double kW = 390;
double kH = 844;
double kCX = 195;
double kBaseY = 607;
double kCandleW = 86;
double kFullH = 258;

final Paint _wickPaint = Paint()
  ..color = const Color(0xFF261709)
  ..strokeWidth = 6.8
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.stroke;

final Paint _smokePaint = Paint()
  ..color = const Color(0x12AAAAAA)
  ..style = PaintingStyle.fill;

final Path _flamePath = Path();
final Path _corePath = Path();
final Path _innerPath = Path();

// ─────────────────────────────────────────────────────────────────────────────
//  NOISE & LERP
// ─────────────────────────────────────────────────────────────────────────────
/// Perlin-like noise function for organic flame movement
/// [x]: spatial coordinate for variation
/// [t]: time parameter for animation progression
/// Returns: value between -1 and 1 for smooth oscillation
double _n(double x, double t) =>
    sin(x * 2.1 + t * 2.0) * 0.4 +
    sin(x * 3.7 + t * 2.7) * 0.25 +
    sin(x * 1.3 + t * 1.2) * 0.35;

/// Linear interpolation between two values
/// [a]: start value
/// [b]: end value  
/// [t]: interpolation factor (0.0 to 1.0)
double _lerp(double a, double b, double t) => a + (b - a) * t;

// ─────────────────────────────────────────────────────────────────────────────
//  CANDLE STATE
// ─────────────────────────────────────────────────────────────────────────────
class CandleState {
  double time = 0;
  double melt = 0;
  bool blown = false;
  double blownAmt = 0;
  int frameCount = 0;
  bool bodyDirty = true;
  final List<Drip> drips = [];
  final List<Particle> particles = [];
  double _nextDrip = 150;
  final Random _rng = Random();

  CandleState() {
    for (int i = 0; i < 25; i++) {
      final p = Particle(_rng, wickY);
      p.life = _rng.nextDouble();
      particles.add(p);
    }
  }

  double get currentH => kFullH * (1 - melt * 0.94);
  /// Y coordinate of the top of the candle (where flame base is)
  double get candleTopY => kBaseY - currentH;
  /// Length of the wick from tip of candle body
  double get wickLen => 16.0;
  /// Y coordinate where the wick tip is (flame originates here)
  double get wickY => candleTopY - wickLen;

  void tick() {
    frameCount++;
    const double timeStep = 0.022; // Animation time progression per frame
    time += timeStep;

    // Blow state fade in/out for smooth transitions
    const double blowInRate = 0.04; // How fast flame extinguishes when blown
    const double blowOutRate = 0.02; // How fast blown state decays
    if (blown) {
      blownAmt = min(1.0, blownAmt + blowInRate);
    } else {
      blownAmt = max(0.0, blownAmt - blowOutRate);
    }

    if (frameCount.isEven) {
      _nextDrip--;
      const double meltThreshold = 0.05; // Minimum melt to start dripping
      if (_nextDrip <= 0 && melt > meltThreshold && !blown) {
        drips.add(Drip(candleTopY, _rng));
        const double baseInterval = 120.0; // Base frames between drips
        const double randomRange = 180.0; // Random variation to interval
        _nextDrip = baseInterval + _rng.nextDouble() * randomRange;
        const int maxDrips = 12; // Maximum concurrent drips
        if (drips.length > maxDrips) drips.removeAt(0);
        bodyDirty = true;
      }
      for (final d in drips) {
        d.update();
      }
      final before = drips.length;
      drips.removeWhere((d) => d.isDead);
      if (drips.length != before) bodyDirty = true;
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
    drips.clear();
    _nextDrip = 150;
    frameCount = 0;
    bodyDirty = true;
  }
}

/// Flame particles: sparks (hot, yellow) and smoke (cool, gray)
/// They rise from the wick with initial velocity and decay over time
class Particle {
  double x, y, vx, vy, life, decay, size;
  bool isSpark; // true: bright spark, false: gray smoke
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
    // Initialize with randomized values for natural variation
    _reset(wickY);
  }

  void _reset(double wickY) {
    // Horizontal spread from wick center
    const double horizontalSpread = 8.0;
    x = kCX + _rng.nextDouble() * horizontalSpread - horizontalSpread / 2;
    
    // Vertical position variance above wick
    const double verticalSpread = 12.0;
    const double verticalOffset = 4.0;
    y = wickY - _rng.nextDouble() * verticalSpread - verticalOffset;
    
    // Horizontal velocity range for particle drift
    const double maxHorizontalVelocity = 1.3;
    vx = _rng.nextDouble() * maxHorizontalVelocity - maxHorizontalVelocity / 2;
    
    // Upward velocity for particles rising
    const double minVerticalVelocity = 1.3;
    const double maxVerticalVariance = 1.5;
    vy = -(_rng.nextDouble() * maxVerticalVariance + minVerticalVelocity);
    
    life = 1;
    
    // Decay rate for particle fade-out
    const double decayBase = 0.013;
    const double decayVariance = 0.015;
    decay = _rng.nextDouble() * decayVariance + decayBase;
    
    // Size variation for visual diversity
    const double minSize = 1.6;
    const double sizeVariance = 1.6;
    size = _rng.nextDouble() * sizeVariance + minSize;
    
    // 62% chance of being a spark, 38% chance of being smoke
    const double sparkProbability = 0.62;
    isSpark = _rng.nextDouble() < sparkProbability;
  }

  void update(Random rng, double wickY) {
    // Apply base velocity + randomness for turbulent movement
    const double turbulenceAmount = 0.45;
    x += vx + rng.nextDouble() * turbulenceAmount - turbulenceAmount / 2;
    y += vy;
    
    // Drag coefficient reduces vertical velocity over time
    const double verticalDrag = 0.975;
    vy *= verticalDrag;
    
    life -= decay;
    
    // Smoke particles grow and slow down
    if (!isSpark) {
      const double smokeGrowthRate = 1.022; // Smoke expands as it cools
      size *= smokeGrowthRate;
      const double smokeDrag = 0.965; // Horizontal drag slows smoke
      vx *= smokeDrag;
    }
    
    if (life <= 0) _reset(wickY);
  }
}

/// Wax drips that form at the candle top and fall due to gravity
/// Two phases: growing (forming at top) then falling (dropping down)
class Drip {
  double x, y, vy = 0, w, length = 0, maxLen;
  bool growing = true; // true: still forming, false: falling
  final Random _rng;

  Drip(double topY, this._rng)
    : // Horizontal position: random offset within candle width
      x = kCX + _rng.nextDouble() * kCandleW * 0.56 - kCandleW * 0.28,
      // Start position at candle top
      y = topY,
      // Width varies: 7-16 pixels
      w = _rng.nextDouble() * 9 + 7,
      // Length varies: 28-83 pixels for visual variety
      maxLen = _rng.nextDouble() * 55 + 28;

  void update() {
    if (growing) {
      // Drip formation speed
      const double dropGrowthMin = 0.4;
      const double dropGrowthMax = 0.6;
      length += _rng.nextDouble() * dropGrowthMax + dropGrowthMin;
      
      if (length >= maxLen) {
        growing = false;
        const double initialFallVelocity = 0.55; // Speed after forming
        vy = initialFallVelocity;
      }
    } else {
      // Drip falls due to gravity
      y += vy;
      const double gravityAccel = 0.05; // Gravity acceleration
      const double maxVelocity = 2.0; // Terminal velocity
      vy = min(vy + gravityAccel, maxVelocity);
    }
  }

  /// Drip is removed when it stops growing and falls below the base (off-screen)
  bool get isDead => !growing && y > kBaseY + 20;
}

// ─────────────────────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class CandleScreen extends StatefulWidget {
  const CandleScreen({super.key});
  @override
  State<CandleScreen> createState() => _CandleScreenState();
}

class _CandleScreenState extends State<CandleScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final CandleState _state = CandleState();
  ui.Picture? _staticPicture;
  ui.Picture? _bodyPicture;
  bool _staticDirty = true;
  final _bodyNotifier = ValueNotifier<int>(0);
  final _flameNotifier = ValueNotifier<int>(0);
  final _timerNotifier = ValueNotifier<int>(60);
  Duration _lastFlameFrameTime = Duration.zero;
  static const Duration _kFlameFrameInterval = Duration(milliseconds: 24);
  Size _lastSize = Size.zero;

  void _updateDimensions(Size size) {
    if (size == _lastSize) return;
    _lastSize = size;
    kW = size.width;
    kH = size.height;
    kCX = kW / 2;
    kBaseY = kH * 0.70;
    kCandleW = (kW * 0.24).clamp(70.0, 140.0);
    kFullH = kCandleW * 3;
    _staticDirty = true;
    _state.bodyDirty = true;
  }

  static const double _kTimerDuration = 60.0;
  DateTime? _timerStartTime;
  double _baseElapsed = 0.0;
  bool _timerRunning = false;
  bool _timerComplete = false;

  double get _timerElapsed {
    if (!_timerRunning || _timerStartTime == null) return _baseElapsed;
    final ms = DateTime.now().difference(_timerStartTime!).inMilliseconds;
    return (_baseElapsed + ms / 1000.0).clamp(0.0, _kTimerDuration);
  }

  int get _timerRemainingSeconds {
    if (_timerComplete) return 0;
    return (_kTimerDuration - _timerElapsed).ceil().clamp(0, 60);
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final shouldRenderFlame =
        elapsed - _lastFlameFrameTime >= _kFlameFrameInterval;
    if (!shouldRenderFlame && !_state.bodyDirty) return;
    if (shouldRenderFlame) {
      _lastFlameFrameTime = elapsed;
      _state.tick();
    }

    if (_staticDirty) {
      _rebuildStaticCache();
      _staticDirty = false;
    }

    if (_timerRunning || _baseElapsed > 0) {
      final elapsed = _timerElapsed;
      final newMelt = (elapsed / _kTimerDuration).clamp(0.0, 1.0);
      if ((newMelt - _state.melt).abs() > 0.0015) {
        _state.melt = newMelt;
        _state.bodyDirty = true;
      }
      if (_timerRunning && elapsed >= _kTimerDuration) {
        _baseElapsed = _kTimerDuration;
        _timerStartTime = null;
        _timerRunning = false;
        _timerComplete = true;
        _state.melt = 1.0;
        _state.blowOut();
        _state.bodyDirty = true;
        if (mounted) setState(() {});
      }

      final remaining = _timerRemainingSeconds;
      if (_timerNotifier.value != remaining) {
        _timerNotifier.value = remaining;
      }
    }

    if (_state.bodyDirty) {
      _rebuildBodyCache();
      _state.bodyDirty = false;
      _bodyNotifier.value++;
    }

    if (shouldRenderFlame) {
      _flameNotifier.value++;
    }
  }

  void _rebuildStaticCache() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, kW, kH));
    _drawBackground(canvas);
    _drawCandleStand(canvas);
    _staticPicture?.dispose();
    _staticPicture = recorder.endRecording();
  }

  void _rebuildBodyCache() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, kW, kH));
    _drawCandleBody(canvas, _state);
    _bodyPicture?.dispose();
    _bodyPicture = recorder.endRecording();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _bodyNotifier.dispose();
    _flameNotifier.dispose();
    _timerNotifier.dispose();
    _staticPicture?.dispose();
    _bodyPicture?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050302),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _updateDimensions(Size(constraints.maxWidth, constraints.maxHeight));
          return Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: ValueListenableBuilder<int>(
                  valueListenable: _bodyNotifier,
                  builder: (_, __, ___) => CustomPaint(
                    painter: _BodyPainter(_staticPicture, _bodyPicture),
                  ),
                ),
              ),
              RepaintBoundary(
                child: ValueListenableBuilder<int>(
                  valueListenable: _flameNotifier,
                  builder: (_, __, ___) =>
                      CustomPaint(painter: _FlamePainter(_state)),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, right: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(
                          Icons.menu_rounded,
                          color: Color(0xFFF5D080),
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MenuSettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xEE050302)],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 52),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ValueListenableBuilder<int>(
                        valueListenable: _timerNotifier,
                        builder: (_, __, ___) {
                          final rem = _timerNotifier.value;
                          final mins = rem ~/ 60;
                          final secs = rem % 60;
                          return Text(
                            '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Color(0xFFF5D080),
                              fontSize: 52,
                              letterSpacing: 6,
                              fontWeight: FontWeight.w200,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _OutlineBtn(
                            label: _timerRunning
                                ? '⏸  Pause'
                                : _timerComplete
                                ? '✓  Done'
                                : (_baseElapsed > 0 ? '▶  Resume' : '▶  Start'),
                            color: const Color(0xFFF5D080),
                            onTap: () {
                              if (_timerComplete) return;
                              if (_timerRunning) {
                                _baseElapsed = _timerElapsed;
                                _timerStartTime = null;
                                _timerRunning = false;
                              } else {
                                _timerStartTime = DateTime.now();
                                _timerRunning = true;
                                if (_state.blown) _state.relight();
                              }
                              _timerNotifier.value = _timerRemainingSeconds;
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 12),
                          _OutlineBtn(
                            label: '↺  Reset',
                            color: const Color(0xFFC8A84A),
                            onTap: () {
                              _baseElapsed = 0.0;
                              _timerStartTime = null;
                              _timerRunning = false;
                              _timerComplete = false;
                              _state.reset();
                              _timerNotifier.value = _timerRemainingSeconds;
                              _state.bodyDirty = true;
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  final ui.Picture? staticPicture;
  final ui.Picture? picture;
  const _BodyPainter(this.staticPicture, this.picture);

  @override
  void paint(Canvas canvas, Size size) {
    if (staticPicture != null) canvas.drawPicture(staticPicture!);
    if (picture != null) canvas.drawPicture(picture!);
  }

  @override
  bool shouldRepaint(_BodyPainter old) =>
      old.staticPicture != staticPicture || old.picture != picture;
}

class _FlamePainter extends CustomPainter {
  final CandleState s;
  const _FlamePainter(this.s);

  @override
  void paint(Canvas canvas, Size size) {
    final wickY = s.wickY;
    _drawAmbientGlow(canvas, wickY, s);
    if (s.blownAmt < 1.0) {
      _drawFlame(canvas, wickY, s);
      _drawParticles(canvas, s);
    } else {
      _drawSmokeOnly(canvas, s);
    }
  }

  @override
  bool shouldRepaint(_FlamePainter old) => true;
}

void _drawBackground(Canvas canvas) {
  final paint = Paint()
    ..shader = const RadialGradient(
      center: Alignment(0, -0.2),
      radius: 0.9,
      colors: [Color(0xFF2A1A0A), Color(0xFF0A0604)],
    ).createShader(Rect.fromLTWH(0, 0, kW, kH));
  canvas.drawRect(Rect.fromLTWH(0, 0, kW, kH), paint);
}

void _drawCandleStand(Canvas canvas) {
  final standTopY = kBaseY - 6;
  final trayW = kCandleW * 1.08;
  final trayH = 14.0;
  final cupW = kCandleW * 0.68;
  final columnH = 26.0;
  final baseW = kCandleW * 0.98;
  final baseH = 30.0;
  final holderBottomY = standTopY + trayH + columnH + baseH + 6;
  final centerX = kCX;

  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(centerX, holderBottomY + 8),
      width: baseW * 1.65,
      height: 12,
    ),
    Paint()
      ..shader =
          const RadialGradient(
            colors: [Color(0x55000000), Colors.transparent],
            stops: [0, 1],
          ).createShader(
            Rect.fromCenter(
              center: Offset(centerX, holderBottomY + 8),
              width: baseW * 1.65,
              height: 12,
            ),
          ),
  );

  final baseRect = Rect.fromCenter(
    center: Offset(centerX, holderBottomY - baseH * 0.18),
    width: baseW,
    height: baseH,
  );
  canvas.drawRRect(
    RRect.fromRectAndCorners(
      baseRect,
      topLeft: const Radius.circular(10),
      topRight: const Radius.circular(10),
      bottomLeft: const Radius.circular(18),
      bottomRight: const Radius.circular(18),
    ),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFF6D4B16),
          Color(0xFFF2D375),
          Color(0xFFC18A2D),
          Color(0xFF7A5619),
        ],
        stops: const [0, 0.36, 0.72, 1],
      ).createShader(baseRect),
  );

  final ringRect = Rect.fromCenter(
    center: Offset(centerX, holderBottomY - baseH - 2),
    width: baseW * 0.58,
    height: 12,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(ringRect, const Radius.circular(6)),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFFF8E39A), Color(0xFFD3A03B), Color(0xFF8D681E)],
      ).createShader(ringRect),
  );

  final supportRect = Rect.fromCenter(
    center: Offset(centerX, standTopY + trayH + columnH / 2),
    width: 14,
    height: columnH,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(supportRect, const Radius.circular(7)),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [Color(0xFF7D591C), Color(0xFFF7DD8D), Color(0xFF7D591C)],
        stops: const [0, 0.5, 1],
      ).createShader(supportRect),
  );

  final collarRect = Rect.fromCenter(
    center: Offset(centerX, standTopY + 10),
    width: trayW * 0.84,
    height: trayH,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(collarRect, const Radius.circular(8)),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFFF8E09C), Color(0xFFD5A43C), Color(0xFF8D651B)],
        stops: const [0, 0.45, 1],
      ).createShader(collarRect),
  );

  final trayRect = Rect.fromCenter(
    center: Offset(centerX, standTopY),
    width: trayW,
    height: trayH,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(trayRect, const Radius.circular(10)),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFFFFE8AE), Color(0xFFE0B34F), Color(0xFF8A621A)],
        stops: const [0, 0.46, 1],
      ).createShader(trayRect),
  );

  final cupRect = Rect.fromCenter(
    center: Offset(centerX, standTopY - 1),
    width: cupW,
    height: 8,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(cupRect, const Radius.circular(5)),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFFFFF0C7), Color(0xFFD9B14D), Color(0xFF8B651C)],
      ).createShader(cupRect),
  );

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(
        centerX - trayW * 0.26,
        standTopY - trayH * 0.16,
        trayW * 0.09,
        holderBottomY - standTopY - 2,
      ),
      const Radius.circular(6),
    ),
    Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [Color(0x88FFFFFF), Colors.transparent],
          ).createShader(
            Rect.fromLTWH(
              centerX - trayW * 0.26,
              standTopY - trayH * 0.16,
              trayW * 0.09,
              holderBottomY - standTopY - 2,
            ),
          ),
  );

  final seatRect = Rect.fromCenter(
    center: Offset(centerX, kBaseY + 2),
    width: kCandleW * 0.74,
    height: 6,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(seatRect, const Radius.circular(4)),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFFFFF4D3), Color(0xFFE0B95D), Color(0xFF926620)],
      ).createShader(seatRect),
  );
}

void _drawCandleBody(Canvas canvas, CandleState s) {
  final topY = s.candleTopY;
  final currentH = s.currentH;
  final cx = kCX - kCandleW / 2;

  if (s.melt > 0.05) {
    final pW = kCandleW * (1 + s.melt * 0.35);
    final pH = 6 + s.melt * 11;
    final center = Offset(kCX, kBaseY);
    final paint = Paint()
      ..shader =
          RadialGradient(
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
  }

  final bodyRRect = RRect.fromRectAndCorners(
    Rect.fromLTWH(cx, topY, kCandleW, currentH),
    topLeft: const Radius.circular(4),
    topRight: const Radius.circular(4),
    bottomLeft: const Radius.circular(6),
    bottomRight: const Radius.circular(6),
  );
  canvas.drawRRect(
    bodyRRect,
    Paint()
      ..shader = LinearGradient(
        colors: const [
          Color(0xFFD4C4A0),
          Color(0xFFF5ECD5),
          Color(0xFFE8D9BE),
          Color(0xFFB8A882),
        ],
        stops: const [0, 0.25, 0.7, 1],
      ).createShader(Rect.fromLTWH(cx, topY, kCandleW, currentH)),
  );

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

  final poolR = min(kCandleW / 2 - 2, 6 + s.melt * 16);
  final topCenter = Offset(kCX, topY);
  canvas.drawOval(
    Rect.fromCenter(center: topCenter, width: kCandleW - 2, height: 18),
    Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFFFFF8E0), Color(0xFFF5E8C0), Color(0xFFD4C4A0)],
        stops: [0, poolR / (kCandleW / 2), 1],
      ).createShader(Rect.fromCircle(center: topCenter, radius: kCandleW / 2)),
  );

  if (s.melt > 0.1) {
    final dipD = min(s.melt * 12, 9.0);
    canvas.drawOval(
      Rect.fromCenter(center: topCenter, width: poolR * 2, height: dipD * 2),
      Paint()
        ..shader =
            RadialGradient(
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

  canvas.drawLine(
    Offset(kCX, topY),
    Offset(kCX + 0.8, topY - s.wickLen),
    _wickPaint,
  );
}

void _drawAmbientGlow(Canvas canvas, double wickY, CandleState s) {
  final flicker = _n(4, s.time) * 0.5 + 0.5;
  final intensity = _lerp(0.25, 0.38, flicker) * (1 - s.blownAmt * 0.9);
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

void _drawFlame(Canvas canvas, double wickY, CandleState s) {
  final t = s.time; // Current animation time
  
  // Brightness flicker: oscillates between 0-1 for height/width variation
  final flicker = _n(0, t) * 0.5 + 0.5;
  
  // Horizontal movement: increases when blown (flame gets displaced)
  const double baseSway = 10.0; // Base horizontal movement range
  const double blowInfluence = 2.3; // How much blown state increases sway
  final sway = _n(1, t) * baseSway * (1 + s.blownAmt * blowInfluence);
  
  // Flame height: interpolates between min and max based on flicker
  const double minFlameHeight = 96.0; // Quietest moment
  const double maxFlameHeight = 150.0; // Peak flicker
  const double blowExtinguishRate = 0.78; // How much blown reduces height
  final h = _lerp(minFlameHeight, maxFlameHeight, flicker) * (1 - s.blownAmt * blowExtinguishRate);
  
  // Flame width: gets wider with flicker and blue effect when blown
  const double minFlameWidth = 21.0;
  const double maxFlameWidth = 30.0;
  const double blowWidthBoost = 0.45; // Widening effect when blown
  final w = _lerp(minFlameWidth, maxFlameWidth, flicker) * (1 + s.blownAmt * blowWidthBoost);
  
  // Base and tip positions for flame shape
  const double baseYOffset = 2.0; // Slight offset from wick
  final baseY = wickY - baseYOffset;
  final tipX = kCX + sway; // Tip sways with wind effect
  final tipY = wickY - h; // Tip height based on flame height

  _flamePath
    ..reset()
    ..moveTo(kCX - w * 0.88, baseY - 0.6)
    ..cubicTo(
      kCX - w * 1.18,
      wickY - h * 0.22,
      kCX - w * 1.05 + sway * 0.2 + _n(2, t) * 2.5,
      wickY - h * 0.66,
      tipX,
      tipY,
    )
    ..cubicTo(
      kCX + w * 1.08 + sway * 0.34 + _n(3, t) * 2.6,
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
    _flamePath,
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

  _corePath
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
    _corePath,
    Paint()
      ..shader =
          LinearGradient(
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

  _innerPath
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
    _innerPath,
    Paint()
      ..shader =
          LinearGradient(
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

  // canvas.drawOval(
  //   Rect.fromCenter(
  //     center: Offset(kCX + sway * 0.06, wickY - 0.8),
  //     width: w * 0.44,
  //     height: 6.2,
  //   ),
  //   Paint()..color = const Color(0x55FFD27A),
  // );

  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(kCX + sway * 0.07, wickY - 1.5),
      width: w * 0.44,
      height: 7.2,
    ),
    Paint()..color = const ui.Color.fromARGB(153, 255, 0, 0),
  );
}

final Paint _sparkPaint = Paint()..style = PaintingStyle.fill;

void _drawParticles(Canvas canvas, CandleState s) {
  for (final p in s.particles) {
    if (p.isSpark) {
      final hue = 40.0 + p.life * 20.0;
      final lightness = 0.6 + p.life * 0.3;
      _sparkPaint.color = HSLColor.fromAHSL(
        p.life * 0.9,
        hue,
        1.0,
        lightness,
      ).toColor();
      canvas.drawCircle(Offset(p.x, p.y), p.size * p.life, _sparkPaint);
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

void _drawSmokeOnly(Canvas canvas, CandleState s) {
  for (final p in s.particles) {
    if (!p.isSpark) {
      canvas.drawCircle(Offset(p.x, p.y), p.size, _smokePaint);
    }
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OutlineBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(204)),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 13, letterSpacing: 1),
      ),
    ),
  );
}
