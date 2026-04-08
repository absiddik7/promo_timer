import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../providers/sound_settings_provider.dart';
import '../providers/candle_simulation_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/visual_settings_provider.dart';
import '../widgets/session_controls_overlay.dart';
import '../widgets/timer_bottom_sheets.dart';
import 'settings_screen.dart';

Color _blend(Color color, Color target, double amount) {
  return Color.lerp(color, target, amount) ?? color;
}

// Candle Strings
final Paint _wickPaint = Paint()
  ..color = Colors.white
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
  late final SoundSettingsProvider _audioSettingsProvider;
  late final VisualSettingsProvider _visualSettingsProvider;
  late final CandleSimulationProvider _candleSimulationProvider;
  CandleState get _state => _candleSimulationProvider.state;
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

  // Stands Positions
  double get _standSize {
    final isNarrowPhone = _lastSize.width <= 390;
    final minStand = isNarrowPhone ? 96.0 : 120.0;
    return (kCandleW * 1.1).clamp(minStand, 250.0);
  }

  double get _standTop => kBaseY - (_standSize * 0.19);

  void _updateDimensions(Size size) {
    if (size == _lastSize) return;
    _lastSize = size;
    kW = size.width;
    kH = size.height;
    kCX = kW / 2;
    final isCompactScreen = kW < 360 || kH < 740;
    final isNarrowPhone = kW <= 390;
    final widthFactor = isCompactScreen ? 0.21 : (isNarrowPhone ? 0.22 : 0.24);
    final minCandleWidth = isCompactScreen
        ? 58.0
        : (isNarrowPhone ? 64.0 : 70.0);
    kCandleW = (kW * widthFactor).clamp(minCandleWidth, 140.0);

    // Keep the candle clear of bottom timer controls across phone sizes.
    final bottomOverlayReserve = (kH * 0.35).clamp(270.0, 340.0);
    final preferredBaseY = isNarrowPhone ? kH * 0.66 : kH * 0.70;
    final maxBaseY = kH - bottomOverlayReserve;
    kBaseY = min(preferredBaseY, maxBaseY).clamp(kH * 0.50, kH * 0.72);

    final heightFactor = isCompactScreen ? 2.6 : 3.0;
    kFullH = kCandleW * heightFactor;
    _staticDirty = true;
    _state.bodyDirty = true;
  }

  bool _pendingFullscreenExitAfterBlowout = false;

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
    _audioSettingsProvider.setTimerActive(false);
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

  Future<void> _openTimerPresetPicker() async {
    final timerProvider = context.read<TimerProvider>();
    if (timerProvider.isRunning) return;
    final selected = await TimerBottomSheets.showTimerPresetPicker(
      context,
      selectedDurationMinutes: timerProvider.selectedDurationMinutes,
    );

    if (selected == null) return;
    if (selected == -1) {
      final customMinutes = await TimerBottomSheets.showCustomTimerDialer(
        context,
        initialMinutes: timerProvider.selectedDurationMinutes,
      );
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
      _candleSimulationProvider.tick();
    }

    if (_staticDirty) {
      _rebuildStaticCache();
      _staticDirty = false;
    }

    final frameState = timerProvider.computeFrameState(now);
    if (frameState.hasStarted) {
      _candleSimulationProvider.setMelt(frameState.meltProgress);

      if (frameState.completedNow) {
        _audioSettingsProvider.setTimerActive(false);
        _candleSimulationProvider.completeAndBlowOut();
        if (_visualSettingsProvider.hapticOnTimerEnd) {
          HapticFeedback.heavyImpact();
        }
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
  void initState() {
    super.initState();
    _candleSimulationProvider = context.read<CandleSimulationProvider>();
    _audioSettingsProvider = context.read<SoundSettingsProvider>();
    _visualSettingsProvider = context.read<VisualSettingsProvider>();
    _audioSettingsProvider.load();
    _visualSettingsProvider.addListener(_handleVisualSettingsChanged);
    _visualSettingsProvider.load();
    _syncVisualColors(_visualSettingsProvider);
    _ticker = createTicker(_onTick)..start();
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
                Positioned(
                  top: _standTop,
                  left: (kW - _standSize) / 2,
                  width: _standSize,
                  height: _standSize,
                  child: IgnorePointer(
                    child: SvgPicture.asset(
                      'assets/icons/Stands_4.svg',
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFD9B14D),
                        BlendMode.srcIn,
                      ),
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
                SessionControlsOverlay(
                  visible: showOverlay,
                  isFullscreen: _isFullscreen,
                  onOpenSettings: () {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => SettingsScreen()));
                  },
                  onOpenTimerPicker: _openTimerPresetPicker,
                  onReset: () {
                    context.read<TimerProvider>().reset();
                    _audioSettingsProvider.setTimerActive(false);
                    _candleSimulationProvider.reset();
                    if (_isFullscreen) {
                      _overlayShownAt = DateTime.now();
                    }
                    setState(() {});
                  },
                  onTogglePlayPause: () {
                    final timerProvider = context.read<TimerProvider>();
                    if (timerProvider.isCompleted) return;
                    timerProvider.toggleRunPause(DateTime.now());
                    if (timerProvider.isRunning) {
                      _audioSettingsProvider.setTimerActive(true);
                      _candleSimulationProvider.relightIfNeeded();
                    } else {
                      _audioSettingsProvider.setTimerActive(false);
                    }
                    if (_isFullscreen) {
                      _overlayShownAt = DateTime.now();
                    }
                    setState(() {});
                  },
                  onToggleFullscreen: _toggleFullscreen,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CandleStaticPreview extends StatelessWidget {
  final Color waxColor;

  const CandleStaticPreview({super.key, required this.waxColor});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewCandleWidth = (constraints.maxWidth * 0.32).clamp(
          34.0,
          56.0,
        );
        final previewBaseY = constraints.maxHeight * 0.78;
        final standSize = (previewCandleWidth * 1.1).clamp(58.0, 120.0);
        final standTop = previewBaseY - (standSize * 0.19);

        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _StaticCandleBodyPreviewPainter(
                waxColor: waxColor,
                candleWidth: previewCandleWidth,
                baseY: previewBaseY,
              ),
            ),
            Positioned(
              top: standTop,
              left: (constraints.maxWidth - standSize) / 2,
              width: standSize,
              height: standSize,
              child: IgnorePointer(
                child: SvgPicture.asset(
                  'assets/icons/Stands_4.svg',
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFD9B14D),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StaticCandleBodyPreviewPainter extends CustomPainter {
  final Color waxColor;
  final double candleWidth;
  final double baseY;

  const _StaticCandleBodyPreviewPainter({
    required this.waxColor,
    required this.candleWidth,
    required this.baseY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final previousKW = kW;
    final previousKH = kH;
    final previousKCX = kCX;
    final previousKBaseY = kBaseY;
    final previousKCandleW = kCandleW;
    final previousKFullH = kFullH;

    kW = size.width;
    kH = size.height;
    kCX = size.width / 2;
    kBaseY = baseY;
    kCandleW = candleWidth;
    kFullH = candleWidth * 2.8;

    final previewState = CandleState()
      ..melt = 0
      ..blown = false
      ..blownAmt = 0;
    previewState.rebuildTopProfile();
    _drawCandleBody(canvas, previewState, waxColor);

    kW = previousKW;
    kH = previousKH;
    kCX = previousKCX;
    kBaseY = previousKBaseY;
    kCandleW = previousKCandleW;
    kFullH = previousKFullH;
  }

  @override
  bool shouldRepaint(_StaticCandleBodyPreviewPainter oldDelegate) {
    return oldDelegate.waxColor != waxColor ||
        oldDelegate.candleWidth != candleWidth ||
        oldDelegate.baseY != baseY;
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
    Paint()..color = const ui.Color.fromARGB(153, 161, 1, 1),
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
