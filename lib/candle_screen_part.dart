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
  ..color = const Color(0xFF3A2A10)
  ..strokeWidth = 2.2
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.stroke;

final Paint _dripPaint = Paint()
  ..color = const Color(0xFFDDB84A)
  ..style = PaintingStyle.fill;

final Paint _dripBulbPaint = Paint()
  ..color = const Color(0xFFC8A030)
  ..style = PaintingStyle.fill;

final Paint _smokePaint = Paint()
  ..color = const Color(0x12AAAAAA)
  ..style = PaintingStyle.fill;

final Path _flamePath = Path();
final Path _corePath = Path();

// ─────────────────────────────────────────────────────────────────────────────
//  NOISE & LERP
// ─────────────────────────────────────────────────────────────────────────────
double _n(double x, double t) =>
    sin(x * 2.1 + t * 1.7) * 0.4 +
    sin(x * 3.7 + t * 2.3) * 0.25 +
    sin(x * 1.3 + t * 0.9) * 0.35;

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

  double get currentH => kFullH * (1 - melt * 0.75);
  double get candleTopY => kBaseY - currentH;
  double get wickLen => max(5.0, 11 - melt * 6);
  double get wickY => candleTopY - wickLen;

  void tick() {
    frameCount++;
    time += 0.018;

    if (blown) {
      blownAmt = min(1.0, blownAmt + 0.04);
    } else {
      blownAmt = max(0.0, blownAmt - 0.02);
    }

    if (frameCount.isEven) {
      _nextDrip--;
      if (_nextDrip <= 0 && melt > 0.05 && !blown) {
        drips.add(Drip(candleTopY, _rng));
        _nextDrip = 120 + _rng.nextDouble() * 180;
        if (drips.length > 12) drips.removeAt(0);
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
    x = kCX + _rng.nextDouble() * 8 - 4;
    y = wickY - _rng.nextDouble() * 12 - 4;
    vx = _rng.nextDouble() * 1.2 - 0.6;
    vy = -(_rng.nextDouble() * 1.3 + 1.2);
    life = 1;
    decay = _rng.nextDouble() * 0.013 + 0.012;
    size = _rng.nextDouble() * 1.5 + 1.5;
    isSpark = _rng.nextDouble() < 0.6;
  }

  void update(Random rng, double wickY) {
    x += vx + rng.nextDouble() * 0.4 - 0.2;
    y += vy;
    vy *= 0.98;
    life -= decay;
    if (!isSpark) {
      size *= 1.02;
      vx *= 0.97;
    }
    if (life <= 0) _reset(wickY);
  }
}

class Drip {
  double x, y, vy = 0, w, length = 0, maxLen;
  bool growing = true;
  final Random _rng;

  Drip(double topY, this._rng)
      : x = kCX + _rng.nextDouble() * kCandleW * 0.56 - kCandleW * 0.28,
        y = topY,
        w = _rng.nextDouble() * 9 + 7,
        maxLen = _rng.nextDouble() * 55 + 28;

  void update() {
    if (growing) {
      length += _rng.nextDouble() * 0.5 + 0.3;
      if (length >= maxLen) {
        growing = false;
        vy = 0.5;
      }
    } else {
      y += vy;
      vy = min(vy + 0.04, 1.8);
    }
  }

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
  ui.Picture? _bodyPicture;
  final _flameNotifier = ValueNotifier<int>(0);
  final _meltNotifier = ValueNotifier<double>(0);
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

  void _onTick(Duration _) {
    _state.tick();
    if (_timerRunning || _baseElapsed > 0) {
      final elapsed = _timerElapsed;
      final newMelt = (elapsed / _kTimerDuration).clamp(0.0, 1.0);
      if ((newMelt - _state.melt).abs() > 0.0003) {
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
      }
    }

    if (_state.bodyDirty) {
      _rebuildBodyCache();
      _state.bodyDirty = false;
      _meltNotifier.value = _state.melt;
    }

    _flameNotifier.value++;
  }

  void _rebuildBodyCache() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, kW, kH));
    _drawBodyLayer(canvas);
    _bodyPicture = recorder.endRecording();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _flameNotifier.dispose();
    _meltNotifier.dispose();
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
                  valueListenable: _flameNotifier,
                  builder: (_, __, ___) => CustomPaint(
                    painter: _BodyPainter(_bodyPicture),
                  ),
                ),
              ),
              RepaintBoundary(
                child: ValueListenableBuilder<int>(
                  valueListenable: _flameNotifier,
                  builder: (_, __, ___) => CustomPaint(
                    painter: _FlamePainter(_state),
                  ),
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
                        valueListenable: _flameNotifier,
                        builder: (_, __, ___) {
                          final rem = _timerRemainingSeconds;
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
                      ValueListenableBuilder<int>(
                        valueListenable: _flameNotifier,
                        builder: (_, __, ___) => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _OutlineBtn(
                              label: _timerRunning
                                  ? '⏸  Pause'
                                  : _timerComplete
                                      ? '✓  Done'
                                      : (_baseElapsed > 0
                                          ? '▶  Resume'
                                          : '▶  Start'),
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
                                _meltNotifier.value = 0;
                              },
                            ),
                          ],
                        ),
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

  void _drawBodyLayer(Canvas canvas) {
    _drawBackground(canvas);
    _drawCandleStand(canvas);
    _drawCandleBody(canvas, _state);
  }
}

class _BodyPainter extends CustomPainter {
  final ui.Picture? picture;
  const _BodyPainter(this.picture);

  @override
  void paint(Canvas canvas, Size size) {
    if (picture != null) canvas.drawPicture(picture!);
  }

  @override
  bool shouldRepaint(_BodyPainter old) => old.picture != picture;
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
      ..shader = const RadialGradient(
        colors: [Color(0x55000000), Colors.transparent],
        stops: [0, 1],
      ).createShader(Rect.fromCenter(
        center: Offset(centerX, holderBottomY + 8),
        width: baseW * 1.65,
        height: 12,
      )),
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
        colors: const [
          Color(0xFFF8E39A),
          Color(0xFFD3A03B),
          Color(0xFF8D681E),
        ],
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
        colors: const [
          Color(0xFF7D591C),
          Color(0xFFF7DD8D),
          Color(0xFF7D591C),
        ],
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
        colors: const [
          Color(0xFFF8E09C),
          Color(0xFFD5A43C),
          Color(0xFF8D651B),
        ],
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
        colors: const [
          Color(0xFFFFE8AE),
          Color(0xFFE0B34F),
          Color(0xFF8A621A),
        ],
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
        colors: const [
          Color(0xFFFFF0C7),
          Color(0xFFD9B14D),
          Color(0xFF8B651C),
        ],
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
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [Color(0x88FFFFFF), Colors.transparent],
      ).createShader(Rect.fromLTWH(
        centerX - trayW * 0.26,
        standTopY - trayH * 0.16,
        trayW * 0.09,
        holderBottomY - standTopY - 2,
      )),
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
        colors: const [
          Color(0xFFFFF4D3),
          Color(0xFFE0B95D),
          Color(0xFF926620),
        ],
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
      ..shader = RadialGradient(
        colors: const [Color(0xFFF0E0B8), Color(0xFFE0D0A8), Colors.transparent],
        stops: const [0, 0.6, 1],
      ).createShader(Rect.fromCenter(center: center, width: pW, height: pH * 2));
    canvas.drawOval(Rect.fromCenter(center: center, width: pW, height: pH), paint);
  }

  for (final d in s.drips) {
    if (d.growing) _drawDrip(canvas, d, topY);
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
        ..shader = RadialGradient(
          colors: [
            const Color(0xD9FFFFFF),
            const Color(0xA6F0DCA0),
            Colors.transparent,
          ],
          stops: const [0, 0.6, 1],
        ).createShader(
          Rect.fromCenter(center: topCenter, width: poolR * 2, height: dipD * 2),
        ),
    );
  }

  canvas.drawLine(
    Offset(kCX, topY),
    Offset(kCX + 0.8, topY - s.wickLen),
    _wickPaint,
  );

  for (final d in s.drips) {
    if (!d.growing) _drawDrip(canvas, d, topY);
  }
}

void _drawDrip(Canvas canvas, Drip d, double topY) {
  if (d.growing) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(d.x - d.w / 2, topY, d.w, d.length),
        Radius.circular(d.w / 2),
      ),
      _dripPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(d.x, topY + d.length),
        width: d.w * 1.4,
        height: d.w * 1.6,
      ),
      _dripBulbPaint,
    );
  } else {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(d.x, d.y),
        width: d.w * 1.1,
        height: d.w * 1.5,
      ),
      _dripPaint,
    );
  }
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
  final t = s.time;
  final flicker = _n(0, t) * 0.5 + 0.5;
  final sway = _n(1, t) * 14 * (1 + s.blownAmt * 3);
  final h = _lerp(88, 116, flicker) * (1 - s.blownAmt * 0.8);
  final w = _lerp(22, 30, flicker) * (1 + s.blownAmt * 0.5);
  final tipX = kCX + sway;
  final tipY = wickY - h;

  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(kCX, wickY - h * 0.4),
      width: w * 4.4,
      height: h * 2.2,
    ),
    Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0x21FF8800),
          Color(0x0FFF4000),
          Colors.transparent,
        ],
        stops: const [0, 0.4, 1],
      ).createShader(Rect.fromCircle(
        center: Offset(kCX + sway * 0.3, wickY - h * 0.5),
        radius: h,
      )),
  );

  _flamePath
    ..reset()
    ..moveTo(kCX - w, wickY - 4)
    ..cubicTo(
      kCX - w - 4,
      wickY - h * 0.5,
      kCX - w * 0.5 + sway * 0.4 + _n(2, t) * 6,
      wickY - h * 0.5,
      tipX,
      tipY,
    )
    ..cubicTo(
      kCX + w * 0.5 + sway * 0.6 + _n(3, t) * 6,
      wickY - h * 0.5,
      kCX + w + 4,
      wickY - h * 0.5,
      kCX + w,
      wickY - 4,
    )
    ..close();

  canvas.drawPath(
    _flamePath,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: const [
          Color(0xFFFFFFCC),
          Color(0xFFFFC832),
          Color(0xFFFF640A),
          Color(0xFFC82805),
          Colors.transparent,
        ],
        stops: const [0, 0.15, 0.45, 0.75, 1],
      ).createShader(Rect.fromLTWH(kCX - w, tipY, w * 2, h)),
  );

  _corePath
    ..reset()
    ..moveTo(kCX - w * 0.28, wickY - 6)
    ..cubicTo(
      kCX - w * 0.15,
      wickY - h * 0.35,
      kCX + sway * 0.4,
      wickY - h * 0.6,
      tipX,
      tipY,
    )
    ..cubicTo(
      kCX + sway * 0.4,
      wickY - h * 0.6,
      kCX + w * 0.15,
      wickY - h * 0.35,
      kCX + w * 0.28,
      wickY - 6,
    )
    ..close();

  canvas.drawPath(
    _corePath,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: const [
          Color(0xFFFFFFF0),
          Color(0xD9FFE678),
          Color(0x00FFB432),
        ],
        stops: const [0, 0.5, 1],
      ).createShader(Rect.fromLTWH(kCX - w * 0.3, tipY, w * 0.6, h * 0.65)),
  );
}

final Paint _sparkPaint = Paint()..style = PaintingStyle.fill;

void _drawParticles(Canvas canvas, CandleState s) {
  for (final p in s.particles) {
    if (p.isSpark) {
      final hue = 40.0 + p.life * 20.0;
      final lightness = 0.6 + p.life * 0.3;
      _sparkPaint.color = HSLColor.fromAHSL(p.life * 0.9, hue, 1.0, lightness).toColor();
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
  const _OutlineBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: color.withAlpha(204)),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(label, style: TextStyle(color: color, fontSize: 13, letterSpacing: 1)),
        ),
      );
}
