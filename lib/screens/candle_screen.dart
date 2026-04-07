import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../providers/timer_provider.dart';
import '../providers/visual_settings_provider.dart';
import 'settings_screen.dart';

Color _blend(Color color, Color target, double amount) {
  return Color.lerp(color, target, amount) ?? color;
}

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
//  PROCEDURAL NOISE HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Multi-octave procedural noise for surface deformation.
/// Combines several sine waves at different frequencies to simulate
/// Perlin-like noise with octave layering.
/// [x]: horizontal position along candle rim [-1, 1]
/// [seed]: per-candle random seed for unique deformation
/// Returns: displacement value, stronger near the rim
double _surfaceNoise(double x, double seed) =>
    sin(x * 3.14 + seed * 1.7) * 0.42 +
    sin(x * 7.28 + seed * 2.3) * 0.28 +
    sin(x * 12.56 + seed * 0.9) * 0.18 +
    sin(x * 19.63 + seed * 3.1) * 0.12;

/// Time-evolving noise for animated surface ripple.
/// Drives the slow undulation of the melt pool surface.
double _meltRippleNoise(double x, double t) =>
    sin(x * 5.0 + t * 0.8) * 0.35 +
    sin(x * 11.0 + t * 1.4) * 0.20 +
    sin(x * 17.0 + t * 0.5) * 0.10;

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
  final List<Particle> particles = [];
  final Random _rng = Random();

  /// Unique seed per candle instance to ensure different surface deformation
  /// patterns each run — drives _surfaceNoise for procedural variety.
  final double noiseSeed = Random().nextDouble() * 100;

  /// Per-column top-surface Y offsets (procedural mesh deformation).
  /// Indexed 0..kMeshColumns. Initialised in _rebuildTopProfile().
  /// Values are Y displacements relative to candleTopY (positive = lower).
  List<double> topProfile = [];

  /// Accumulator that drives profile rebuilds; rebuilt whenever melt changes.
  double _lastProfileMelt = -1;

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

  /// Number of horizontal mesh columns for top-surface deformation
  static const int kMeshColumns = 32;

  /// Rebuild the procedural top-surface height profile.
  /// Called whenever melt changes significantly.
  /// Each column gets a noise-displaced Y offset so the top is uneven.
  /// Vertices near the rim deform more; the centre stays relatively flat.
  void rebuildTopProfile() {
    _lastProfileMelt = melt;
    topProfile = List.generate(kMeshColumns + 1, (i) {
      // Normalised position across the candle width: -1 (left) to +1 (right)
      final nx = (i / kMeshColumns) * 2.0 - 1.0;

      // Rim proximity: edges deform more, but centre also stays uneven.
      final rimWeight = 0.35 + 0.65 * pow(nx.abs(), 0.8);

      // Base noise value — unique per column and candle seed
      final noise = _surfaceNoise(nx, noiseSeed);

      // Higher-frequency ridges to avoid a smooth or flat-looking top.
      final ridges =
          sin(nx * 31.4 + noiseSeed * 0.7) * 0.12 +
          sin(nx * 47.1 + noiseSeed * 1.9) * 0.08;

      // Keep slight roughness even before heavy melt, then amplify over time.
      final maxDeform = (2.5 + melt * 18.0) * rimWeight;

      return (noise + ridges) * maxDeform;
    });
  }

  /// Returns the Y displacement for a given normalised X position [-1, 1].
  /// Interpolates between adjacent mesh columns for smooth deformation.
  double topProfileAt(double nx) {
    if (topProfile.isEmpty) return 0;
    // Map nx from [-1,1] to [0, kMeshColumns]
    final t = (nx + 1.0) / 2.0 * kMeshColumns;
    final lo = t.floor().clamp(0, kMeshColumns - 1);
    final hi = (lo + 1).clamp(0, kMeshColumns);
    final frac = t - lo;
    final a = topProfile[lo];
    final b = topProfile[hi.clamp(0, topProfile.length - 1)];
    return a + (b - a) * frac;
  }

  /// Returns the visible top-surface Y at a candle X coordinate.
  /// Includes both the procedural rim deformation and any local drip cutouts.
  double surfaceYAtX(double x) {
    final halfWidth = kCandleW / 2;
    if (halfWidth <= 0) return candleTopY;
    final nx = (((x - kCX) / halfWidth).clamp(-1.0, 1.0)).toDouble();
    final centerBias = 1.0 - nx.abs();
    final centerDip = melt * 5.5 * pow(centerBias, 1.45);
    // Rounded top shoulders at initial stage, using a smooth edge mask.
    final edgeMix = ((nx.abs() - 0.62) / 0.38).clamp(0.0, 1.0).toDouble();
    final cornerMask = edgeMix * edgeMix * (3 - 2 * edgeMix);
    final earlyRoundStrength = (1.0 - (melt / 0.24).clamp(0.0, 1.0)) * 4.8;
    final cornerRound = cornerMask * earlyRoundStrength;
    return candleTopY + topProfileAt(nx) + centerDip + cornerRound;
  }

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

    // Rebuild top profile when melt changes enough
    if ((melt - _lastProfileMelt).abs() > 0.005 || topProfile.isEmpty) {
      rebuildTopProfile();
    }

    if (frameCount.isEven) {
      // Drips removed by design: candle now melts via top surface deformation.
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
  late final VisualSettingsProvider _visualSettingsProvider;
  final CandleState _state = CandleState();
  ui.Picture? _staticPicture;
  ui.Picture? _bodyPicture;
  bool _staticDirty = true;
  final _bodyNotifier = ValueNotifier<int>(0);
  final _flameNotifier = ValueNotifier<int>(0);
  Duration _lastFlameFrameTime = Duration.zero;
  static const Duration _kFlameFrameInterval = Duration(milliseconds: 24);
  Size _lastSize = Size.zero;
  bool _isFullscreen = false;
  bool _showOverlayControls = true;
  DateTime _overlayShownAt = DateTime.fromMillisecondsSinceEpoch(0);
  Duration _overlayVisibleDuration = const Duration(seconds: 5);
  Color _backgroundInnerColor = const Color(0xFF2A1A0A);
  Color _backgroundOuterColor = const Color(0xFF0A0604);
  Color _candleBodyColor = const Color(0xFFD4C4A0);

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

  bool _pendingFullscreenExitAfterBlowout = false;

  @override
  void initState() {
    super.initState();
    _visualSettingsProvider = context.read<VisualSettingsProvider>();
    _visualSettingsProvider.addListener(_handleVisualSettingsChanged);
    _visualSettingsProvider.load();
    _syncVisualColors(_visualSettingsProvider);
    _ticker = createTicker(_onTick)..start();
  }

  void _syncVisualColors(VisualSettingsProvider provider) {
    _backgroundInnerColor = provider.backgroundInnerColor;
    _backgroundOuterColor = provider.backgroundOuterColor;
    _candleBodyColor = provider.candleBodyColor;
  }

  void _handleVisualSettingsChanged() {
    if (!mounted) return;
    _syncVisualColors(_visualSettingsProvider);
    _staticDirty = true;
    _state.bodyDirty = true;
  }

  void _applySelectedDurationMinutes(int minutes) {
    final timerProvider = context.read<TimerProvider>();
    timerProvider.setDurationMinutes(minutes);
    setState(() {
      _pendingFullscreenExitAfterBlowout = false;
      _state.reset();
      _state.bodyDirty = true;
      if (_isFullscreen) {
        _showOverlayControls = true;
        _overlayShownAt = DateTime.now();
        _overlayVisibleDuration = const Duration(seconds: 5);
      }
    });
  }

  Future<int?> _openCustomTimerDialer() async {
    int tempMinutes = context.read<TimerProvider>().selectedDurationMinutes;
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF15100A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Color(0xFFC8A84A)),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(tempMinutes),
                        child: const Text(
                          'Set',
                          style: TextStyle(color: Color(0xFFF5D080)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Custom Timer',
                    style: TextStyle(
                      color: Color(0xFFF5D080),
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 180,
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hm,
                      initialTimerDuration: Duration(minutes: tempMinutes),
                      onTimerDurationChanged: (duration) {
                        final minutes = max(1, duration.inMinutes);
                        setSheetState(() {
                          tempMinutes = minutes;
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openTimerPresetPicker() async {
    final timerProvider = context.read<TimerProvider>();
    if (timerProvider.isRunning) return;
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF15100A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set Timer',
                style: TextStyle(
                  color: Color(0xFFF5D080),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: TimerProvider.presetsMinutes.map((m) {
                  final isSelected = m == timerProvider.selectedDurationMinutes;
                  return ChoiceChip(
                    label: Text('$m min'),
                    selected: isSelected,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF1C1208)
                          : const Color(0xFFF5D080),
                      fontWeight: FontWeight.w500,
                    ),
                    selectedColor: const Color(0xFFF5D080),
                    backgroundColor: const Color(0x332A1A0A),
                    side: const BorderSide(color: Color(0x66F5D080)),
                    onSelected: (_) => Navigator.of(context).pop(m),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(-1),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0x66F5D080)),
                    foregroundColor: const Color(0xFFF5D080),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.timer_outlined),
                  label: const Text('Custom time'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) return;
    if (selected == -1) {
      final customMinutes = await _openCustomTimerDialer();
      if (customMinutes == null ||
          customMinutes == timerProvider.selectedDurationMinutes) {
        return;
      }
      _applySelectedDurationMinutes(customMinutes);
      return;
    }
    if (selected == timerProvider.selectedDurationMinutes) return;
    _applySelectedDurationMinutes(selected);
  }

  void _setFullscreenSystemUi(bool enabled) {
    if (enabled) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _showOverlayFor(Duration duration) {
    if (!_isFullscreen) return;
    setState(() {
      _showOverlayControls = true;
      _overlayShownAt = DateTime.now();
      _overlayVisibleDuration = duration;
    });
  }

  void _toggleFullscreen() {
    final enteringFullscreen = !_isFullscreen;
    _setFullscreenSystemUi(enteringFullscreen);
    if (enteringFullscreen) {
      setState(() {
        _isFullscreen = true;
        _showOverlayControls = true;
        _overlayShownAt = DateTime.now();
        _overlayVisibleDuration = const Duration(seconds: 1);
        _pendingFullscreenExitAfterBlowout = false;
      });
      return;
    }

    setState(() {
      _isFullscreen = false;
      _showOverlayControls = true;
      _overlayVisibleDuration = const Duration(seconds: 5);
      _pendingFullscreenExitAfterBlowout = false;
    });
  }

  void _onTick(Duration elapsed) {
    final timerProvider = context.read<TimerProvider>();
    final now = DateTime.now();
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

    if (timerProvider.isRunning ||
        timerProvider.remainingSeconds <
            timerProvider.selectedDurationMinutes * 60) {
      final timerElapsed = timerProvider.elapsedSecondsAt(now);
      final newMelt = (timerElapsed / timerProvider.durationSeconds).clamp(
        0.0,
        1.0,
      );
      if ((newMelt - _state.melt).abs() > 0.0015) {
        _state.melt = newMelt;
        _state.bodyDirty = true;
      }

      final completedNow = timerProvider.tick(now);
      if (completedNow) {
        _state.melt = 1.0;
        _state.blowOut();
        _state.bodyDirty = true;
        if (_isFullscreen) {
          _pendingFullscreenExitAfterBlowout = true;
        }
        if (mounted) setState(() {});
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

    if (_isFullscreen &&
        _showOverlayControls &&
        DateTime.now().difference(_overlayShownAt) >= _overlayVisibleDuration) {
      setState(() {
        _showOverlayControls = false;
      });
    }

    // Exit fullscreen only after flame is fully extinguished.
    if (_pendingFullscreenExitAfterBlowout && _state.blownAmt >= 0.999) {
      _pendingFullscreenExitAfterBlowout = false;
      _setFullscreenSystemUi(false);
      setState(() {
        _isFullscreen = false;
        _showOverlayControls = true;
        _overlayVisibleDuration = const Duration(seconds: 5);
      });
    }
  }

  void _rebuildStaticCache() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, kW, kH));
    _drawBackground(canvas, _backgroundInnerColor, _backgroundOuterColor);
    _drawCandleStand(canvas);
    _staticPicture?.dispose();
    _staticPicture = recorder.endRecording();
  }

  void _rebuildBodyCache() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, kW, kH));
    _drawCandleBody(canvas, _state, _candleBodyColor);
    _bodyPicture?.dispose();
    _bodyPicture = recorder.endRecording();
  }

  @override
  void dispose() {
    _setFullscreenSystemUi(false);
    _visualSettingsProvider.removeListener(_handleVisualSettingsChanged);
    _ticker.dispose();
    _bodyNotifier.dispose();
    _flameNotifier.dispose();
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
          final showOverlay = !_isFullscreen || _showOverlayControls;
          _updateDimensions(Size(constraints.maxWidth, constraints.maxHeight));
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _isFullscreen
                ? () => _showOverlayFor(const Duration(seconds: 5))
                : null,
            child: Stack(
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
                if (showOverlay)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, right: 8),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: !_isFullscreen
                              ? _IconControlBtn(
                                  icon: Icons.menu_rounded,
                                  color: const Color(0xFFF5D080),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => SettingsScreen(),
                                      ),
                                    );
                                  },
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                if (showOverlay)
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
                          Consumer<TimerProvider>(
                            builder: (context, timerProvider, _) {
                              return GestureDetector(
                                onTap: _openTimerPresetPicker,
                                child: Text(
                                  TimerProvider.formatRemainingTime(
                                    timerProvider.remainingSeconds,
                                  ),
                                  style: TextStyle(
                                    color: const Color(0xFFF5D080),
                                    fontSize: _isFullscreen ? 56 : 52,
                                    letterSpacing: 6,
                                    fontWeight: FontWeight.w200,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _IconControlBtn(
                                icon: Icons.refresh_rounded,
                                color: const Color(0xFFC8A84A),
                                onTap: () {
                                  context.read<TimerProvider>().reset();
                                  _state.reset();
                                  _state.bodyDirty = true;
                                  if (_isFullscreen) {
                                    _overlayShownAt = DateTime.now();
                                  }
                                  setState(() {});
                                },
                              ),
                              const SizedBox(width: 12),
                              Consumer<TimerProvider>(
                                builder: (context, timerProvider, _) {
                                  return _IconControlBtn(
                                    icon: timerProvider.isRunning
                                        ? Icons.pause_rounded
                                        : (timerProvider.isCompleted
                                              ? Icons.check_rounded
                                              : Icons.play_arrow_rounded),
                                    color: const Color(0xFFF5D080),
                                    size: 62,
                                    iconSize: 42,
                                    onTap: () {
                                      if (timerProvider.isCompleted) return;
                                      timerProvider.toggleRunPause(
                                        DateTime.now(),
                                      );
                                      if (timerProvider.isRunning &&
                                          _state.blown) {
                                        _state.relight();
                                      }
                                      if (_isFullscreen) {
                                        _overlayShownAt = DateTime.now();
                                      }
                                      setState(() {});
                                    },
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              _IconControlBtn(
                                icon: _isFullscreen
                                    ? Icons.fullscreen_exit_rounded
                                    : Icons.fullscreen_rounded,
                                color: const Color(0xFFF5D080),
                                onTap: _toggleFullscreen,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
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
      // Heat distortion shimmer above flame
      _drawHeatDistortion(canvas, wickY, s);
    } else {
      _drawSmokeOnly(canvas, s);
    }
  }

  @override
  bool shouldRepaint(_FlamePainter old) => true;
}

void _drawBackground(
  Canvas canvas,
  Color backgroundInnerColor,
  Color backgroundOuterColor,
) {
  final paint = Paint()
    ..shader = RadialGradient(
      center: Alignment(0, -0.2),
      radius: 0.9,
      colors: [backgroundInnerColor, backgroundOuterColor],
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

// ─────────────────────────────────────────────────────────────────────────────
//  CANDLE BODY — procedural mesh deformation & advanced drip rendering
// ─────────────────────────────────────────────────────────────────────────────

void _drawCandleBody(Canvas canvas, CandleState s, Color candleBodyColor) {
  final topY = s.candleTopY;
  final currentH = s.currentH;
  final cx = kCX - kCandleW / 2;

  // ── 1. Wax pool puddle at base ─────────────────────────────────────────────
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

    // Glossy sheen on the wax pool (melted = more shiny)
    final glossW = pW * 0.38;
    final glossH = pH * 0.55;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(kCX - pW * 0.12, kBaseY - pH * 0.18),
        width: glossW,
        height: glossH,
      ),
      Paint()
        ..shader =
            RadialGradient(
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
  // Build a deformed side profile using the mesh columns.
  // Left and right edges gain slight noise-driven bulge near the top rim,
  // simulating a soft cylinder deforming as it melts.
  final bodyPath = Path();
  const int sideSteps = 24; // Vertical resolution of side deformation

  // Left edge — bottom to top
  bodyPath.moveTo(cx, kBaseY);
  for (int i = 0; i <= sideSteps; i++) {
    final t = i / sideSteps; // 0 = bottom, 1 = top
    final yPos = kBaseY - currentH * t;
    // Side melt should be soft and elongated, not jagged.
    final deformStrength = pow(t, 2.4) * s.melt * 1.6;
    final sideWave =
        sin(t * 2.7 + s.noiseSeed * 0.42) * 0.55 +
        sin(t * 5.1 + s.noiseSeed * 0.19) * 0.28;
    final wobble = sideWave * deformStrength;
    bodyPath.lineTo(cx + wobble, yPos);
  }

  // Top edge — left to right using per-column top profile
  const int topSteps = CandleState.kMeshColumns;
  for (int i = 0; i <= topSteps; i++) {
    final nx = (i / topSteps) * 2.0 - 1.0; // -1 to +1
    final xPos = kCX + nx * kCandleW / 2;
    bodyPath.lineTo(xPos, s.surfaceYAtX(xPos));
  }

  // Right edge — top to bottom
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

  // Draw main body with cylindrical gradient (matte on sides, slightly glossy)
  canvas.drawPath(
    bodyPath,
    Paint()
      ..shader = LinearGradient(
        colors: [
          _blend(candleBodyColor, Colors.black, 0.18),
          _blend(candleBodyColor, Colors.white, 0.38),
          _blend(candleBodyColor, Colors.white, 0.22),
          _blend(candleBodyColor, Colors.black, 0.34),
        ],
        stops: const [0, 0.25, 0.7, 1],
      ).createShader(Rect.fromLTWH(cx, topY, kCandleW, currentH)),
  );

  // Vertical highlight strip (simulates cylindrical specularity)
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
  // Melted areas near the top get a translucent gloss overlay.
  // Solid (lower) areas remain matte by having no overlay.
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

  // ── 4. Deformed top surface (uneven melt rim) ──────────────────────────────
  // Draw the deformed top cap as a filled path that follows the same
  // per-column displacement profile used for the body.
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

    // Wax pool on top — colour transitions from ivory to warm amber as it melts
    final poolColor = Color.lerp(
      _blend(candleBodyColor, Colors.white, 0.45),
      const Color(0xFFFFE4A0),
      s.melt,
    )!;

    canvas.drawPath(
      topPath,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                _blend(poolColor, Colors.white, 0.45),
                _blend(poolColor, Colors.white, 0.25),
                _blend(poolColor, Colors.black, 0.15),
              ],
              stops: const [0, 0.6, 1],
            ).createShader(
              Rect.fromCircle(center: Offset(kCX, topY), radius: kCandleW / 2),
            ),
    );

    // Melt pool ripple highlight — driven by time-varying noise
    if (s.melt > 0.1) {
      final ripplePath = Path();
      bool rippleStarted = false;
      for (int i = 0; i <= topSteps; i++) {
        final nx = (i / topSteps) * 2.0 - 1.0;
        final xPos = kCX + nx * kCandleW / 2;
        final baseY = s.surfaceYAtX(xPos);
        // Add a time-varying ripple on top of the static deformation
        final ripple = _meltRippleNoise(nx, s.time) * s.melt * 2.2;
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

    // Wax dip (concave shadow in melt pool centre)
    final dipD = min(s.melt * 12, 9.0);
    if (dipD > 0) {
      final poolR = min(kCandleW / 2 - 2, 6 + s.melt * 16);
      final topCenter = Offset(kCX, topY);
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
  }

  // ── 5. Wick ─────────────────────────────────────────────────────────────────
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

/// Draws subtle heat distortion above the flame using stacked translucent ovals.
///
/// The shimmer is driven by the same time-varying noise that animates the flame,
/// creating a heat-haze effect near the tip.  Opacity is modulated by flicker
/// and suppressed when the flame is blown out ([s.blownAmt]).
void _drawHeatDistortion(Canvas canvas, double wickY, CandleState s) {
  if (s.blownAmt > 0.85) return;
  final t = s.time;
  final flicker = _n(7, t) * 0.5 + 0.5;
  final baseOpacity = (0.04 + flicker * 0.05) * (1 - s.blownAmt);

  // Stack several semi-transparent ovals with oscillating offsets
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

void _drawFlame(Canvas canvas, double wickY, CandleState s) {
  final t = s.time; // Current animation time
  final endPhase = ((s.melt - 0.8) / 0.2).clamp(0.0, 1.0);
  final endScale = _lerp(1.0, 0.55, endPhase);

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
  final h =
      _lerp(minFlameHeight, maxFlameHeight, flicker) *
      (1 - s.blownAmt * blowExtinguishRate) *
      endScale;

  // Flame width: gets wider with flicker and blue effect when blown
  const double minFlameWidth = 21.0;
  const double maxFlameWidth = 30.0;
  const double blowWidthBoost = 0.45; // Widening effect when blown
  final w =
      _lerp(minFlameWidth, maxFlameWidth, flicker) *
      (1 + s.blownAmt * blowWidthBoost) *
      endScale;

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

  // Flickering flame-light highlight on the candle body (dynamic rim lighting)
  // Brightens the top portion of the candle body in sync with flame flicker.
  if (s.blownAmt < 0.8) {
    final rimLightAlpha = ((flicker * 0.55 + 0.1) * (1 - s.blownAmt) * 255)
        .toInt()
        .clamp(0, 130);
    final rimCenter = Offset(kCX + sway * 0.15, s.candleTopY + 2);
    canvas.drawOval(
      Rect.fromCenter(center: rimCenter, width: kCandleW * 0.82, height: 22),
      Paint()
        ..shader =
            RadialGradient(
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

class _IconControlBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  const _IconControlBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 52,
    this.iconSize = 26,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: IconButton(
      onPressed: onTap,
      splashRadius: size * 0.46,
      icon: Icon(icon, color: color, size: iconSize),
    ),
  );
}
