import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/candle_simulation_provider.dart';
import 'candle_painter_utils.dart';

/// A reusable candle widget that renders the exact candle from CandleScreen.
/// Includes the stand and optional background to ensure 100% visual parity.
class CandleWidget extends StatefulWidget {
  final double size;
  final Color candleColor;
  final double meltProgress; // 0 to 1
  final bool isAnimated;
  final bool isBlown;
  final Duration? duration; // If provided, handles its own melting animation
  final bool showStand;
  final bool showBackground;
  final double flameScale;
  final bool isFlameLive;

  const CandleWidget({
    super.key,
    this.size = 200,
    this.candleColor = const Color(0xFFD4C4A0),
    this.meltProgress = 0,
    this.isAnimated = false,
    this.isBlown = false,
    this.duration,
    this.showStand = true,
    this.showBackground = false,
    this.flameScale = 1.0,
    this.isFlameLive = true,
  });

  @override
  State<CandleWidget> createState() => _CandleWidgetState();
}

class _CandleWidgetState extends State<CandleWidget>
    with SingleTickerProviderStateMixin {
  late CandleState _candleState;
  Ticker? _ticker;
  bool _isDisposed = false;
  double _internalMeltProgress = 0;
  late DateTime _startTime;
  bool _oldBlown = false;

  @override
  void initState() {
    super.initState();
    _candleState = CandleState();
    _candleState.targetMelt = widget.meltProgress;
    _candleState.blown = widget.isBlown;
    _internalMeltProgress = widget.meltProgress;
    _startTime = DateTime.now();
    _oldBlown = widget.isBlown;

    if (widget.isAnimated || widget.duration != null) {
      _startTicker();
    }
  }

  void _startTicker() {
    if (_ticker != null) return;
    _ticker = createTicker((elapsed) {
      if (!_isDisposed) {
        // MUST set globals before tick() so particles use correct coordinates
        final candleWidth = widget.size * 0.24;
        final baseY = widget.size * 0.72;
        
        kW = widget.size;
        kH = widget.size;
        kCX = widget.size / 2;
        kBaseY = baseY;
        kCandleW = candleWidth;
        final isCompactScreen = kW < 360 || kH < 740;
        kFullH = kCandleW * (isCompactScreen ? 2.6 : 3.0);

        if (widget.duration != null) {
          if (!_candleState.blown) {
            final now = DateTime.now();
            final diff = now.difference(_startTime);
            _internalMeltProgress = (diff.inMilliseconds / widget.duration!.inMilliseconds).clamp(0.0, 1.0);
            _candleState.targetMelt = _internalMeltProgress;
            
            if (_internalMeltProgress >= 1.0) {
              _candleState.blown = true;
            }
          }
        } else {
          _candleState.targetMelt = widget.meltProgress;
          _candleState.blown = widget.isBlown;
          
          if (widget.meltProgress >= 0.99 && widget.isAnimated) {
             _candleState.blown = true;
          }
        }
        
        _candleState.tick();
        if (mounted) setState(() {});
      }
    });
    _ticker!.start();
  }

  void _stopTicker() {
    if (_ticker != null) {
      _ticker!.stop();
      _ticker = null;
    }
  }

  @override
  void didUpdateWidget(CandleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.isAnimated || widget.duration != null) && _ticker == null) {
      _startTicker();
    } else if (!widget.isAnimated && widget.duration == null && _ticker != null) {
      _stopTicker();
    }
    
    if (widget.duration == null) {
      _candleState.targetMelt = widget.meltProgress;
      if (widget.isBlown != _oldBlown) {
         _candleState.blown = widget.isBlown;
         _oldBlown = widget.isBlown;
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopTicker();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.duration == null) {
      _candleState.targetMelt = widget.meltProgress;
      if (widget.isBlown != _oldBlown) {
         _candleState.blown = widget.isBlown;
         _oldBlown = widget.isBlown;
      }
    }

    // Proportions matching CandleScreen
    final candleWidth = widget.size * 0.24;
    final standSize = candleWidth * 1.1;
    final baseY = widget.size * 0.72;
    final standTop = baseY - (standSize * 0.19);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (widget.showBackground)
            Positioned.fill(
              child: CustomPaint(
                painter: _BackgroundPainter(),
              ),
            ),
          if (widget.showStand)
            Positioned(
              top: standTop,
              left: (widget.size - standSize) / 2,
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
          Positioned.fill(
            child: CustomPaint(
              painter: _ReusableCandlePainter(
                candleState: _candleState,
                candleColor: widget.candleColor,
                baseY: baseY,
                candleWidth: candleWidth,
                flameScale: widget.flameScale,
                isFlameLive: widget.isFlameLive,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    drawBackground(
      canvas,
      size.width,
      size.height,
      const Color(0xFF2A1A0A),
      const Color(0xFF0A0604),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _ReusableCandlePainter extends CustomPainter {
  final CandleState candleState;
  final Color candleColor;
  final double baseY;
  final double candleWidth;
  final double flameScale;
  final bool isFlameLive;

  _ReusableCandlePainter({
    required this.candleState,
    required this.candleColor,
    required this.baseY,
    required this.candleWidth,
    required this.flameScale,
    required this.isFlameLive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Preserve globals
    final prevKW = kW;
    final prevKH = kH;
    final prevKCX = kCX;
    final prevKBaseY = kBaseY;
    final prevKCandleW = kCandleW;
    final prevKFullH = kFullH;

    // Set dimensions for this widget instance
    kW = size.width;
    kH = size.height;
    kCX = size.width / 2;
    kBaseY = baseY;
    kCandleW = candleWidth;
    
    final isCompactScreen = kW < 360 || kH < 740;
    final heightFactor = isCompactScreen ? 2.6 : 3.0;
    kFullH = kCandleW * heightFactor;

    // Draw using shared utility functions
    drawCandleBody(canvas, candleState, candleColor);
    final wickY = candleState.wickY;
    drawAmbientGlow(canvas, wickY, candleState);
    
    if (candleState.blownAmt < 1.0) {
      drawFlame(
        canvas,
        wickY,
        candleState,
        flameScale: flameScale,
        isAnimated: isFlameLive,
      );
      if (isFlameLive) {
        drawParticles(canvas, candleState);
        drawHeatDistortion(canvas, wickY, candleState);
      }
    } else {
      drawSmokeOnly(canvas, candleState);
    }

    // Restore globals
    kW = prevKW;
    kH = prevKH;
    kCX = prevKCX;
    kBaseY = prevKBaseY;
    kCandleW = prevKCandleW;
    kFullH = prevKFullH;
  }

  @override
  bool shouldRepaint(_ReusableCandlePainter oldDelegate) => true;
}
