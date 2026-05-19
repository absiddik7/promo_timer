import 'dart:async';
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
import '../widgets/candle_painter_utils.dart';
import '../widgets/session_controls_overlay.dart';
import '../widgets/timer_bottom_sheets.dart';
import 'settings_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  NOISE & LERP
// ─────────────────────────────────────────────────────────────────────────────
/// Perlin-like noise function for organic flame movement
// Moved to candle_painter_utils.dart

/// Linear interpolation between two values
// Moved to candle_painter_utils.dart

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
  Duration _overlayVisibleDuration = const Duration(seconds: 3);
  static const Duration _kFullscreenOverlayAutoHideDuration = Duration(
    seconds: 3,
  );
  Color _backgroundInnerColor = const Color(0xFF2A1A0A);
  Color _backgroundOuterColor = const Color(0xFF0A0604);
  Color _candleBodyColor = const Color(0xFFD4C4A0);
  bool _lastTimerCompletedState = false;

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
      _lastTimerCompletedState = false;
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
      presetMinutes: timerProvider.presetMinutes,
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

  void _showFullscreenToast(bool enabled) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 900),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        backgroundColor: const Color(0xDD111111),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        content: Text(
          enabled ? 'Fullscreen Mode ON' : 'Fullscreen Mode OFF',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _toggleFullscreen() {
    final enteringFullscreen = !_isFullscreen;
    _setFullscreenSystemUi(enteringFullscreen);
    if (enteringFullscreen) {
      setState(() {
        _isFullscreen = true;
        _showOverlayControls = true;
        _overlayShownAt = DateTime.now();
        _overlayVisibleDuration = _kFullscreenOverlayAutoHideDuration;
        _pendingFullscreenExitAfterBlowout = false;
      });
      _showFullscreenToast(true);
      return;
    }

    setState(() {
      _isFullscreen = false;
      _showOverlayControls = true;
      _overlayVisibleDuration = _kFullscreenOverlayAutoHideDuration;
      _pendingFullscreenExitAfterBlowout = false;
    });
    _showFullscreenToast(false);
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
    }

    if (timerProvider.isCompleted != _lastTimerCompletedState) {
      _lastTimerCompletedState = timerProvider.isCompleted;
      _candleSimulationProvider.state.setWaxDropsFrozen(
        timerProvider.isCompleted,
      );
      if (timerProvider.isCompleted && _isFullscreen) {
        _pendingFullscreenExitAfterBlowout = true;
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
    drawBackground(canvas, kW, kH, _backgroundInnerColor, _backgroundOuterColor);
    _staticPicture?.dispose();
    _staticPicture = recorder.endRecording();
  }

  void _rebuildBodyCache() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, kW, kH));
    drawCandleBody(canvas, _state, _candleBodyColor);
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
                ? () => _showOverlayFor(_kFullscreenOverlayAutoHideDuration)
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
                    _lastTimerCompletedState = false;
                    setState(() {});
                  },
                  onTogglePlayPause: () {
                    final timerProvider = context.read<TimerProvider>();
                    if (timerProvider.isCompleted) return;
                    timerProvider.toggleRunPause(DateTime.now());
                    if (timerProvider.isRunning) {
                      _audioSettingsProvider.setTimerActive(true);
                      _candleSimulationProvider.relightIfNeeded();
                      _lastTimerCompletedState = false;
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
    drawCandleBody(canvas, previewState, waxColor);

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
    drawAmbientGlow(canvas, wickY, s);
    if (s.blownAmt < 1.0) {
      drawFlame(canvas, wickY, s);
      drawParticles(canvas, s);
      drawHeatDistortion(canvas, wickY, s);
    } else {
      drawSmokeOnly(canvas, s);
    }
  }

  @override
  bool shouldRepaint(_FlamePainter old) => true;
}
