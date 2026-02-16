import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import '../models/models.dart';
import '../utils/lottie_animation_manager.dart';

/// A Lottie-based timer animation widget that syncs animation with timer state.
/// 
/// This widget replaces CustomPaint-based visualizations with Lottie animations.
/// The candle burn animation is synced to timer progress, while flame animations
/// play continuously to show a flickering fire effect.

class LottieTimerAnimation extends StatefulWidget {
  /// The current timer state containing progress (0.0-1.0).
  final TimerState timerState;

  /// The selected sensory theme that determines which Lottie animation to use.
  final SensoryTheme selectedTheme;

  const LottieTimerAnimation({
    Key? key,
    required this.timerState,
    required this.selectedTheme,
  }) : super(key: key);

  @override
  State<LottieTimerAnimation> createState() => _LottieTimerAnimationState();
}

class _LottieTimerAnimationState extends State<LottieTimerAnimation>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _flameController;
  String _currentAnimationPath = '';
  Timer? _progressUpdateTimer;
  LottieComposition? _composition;

  @override
  void initState() {
    super.initState();
    _currentAnimationPath =
        LottieAnimationManager.getAnimationPath(widget.selectedTheme);
    _initializeControllers();
  }

  @override
  void didUpdateWidget(LottieTimerAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If theme changed, update animation path
    if (oldWidget.selectedTheme != widget.selectedTheme) {
      _currentAnimationPath =
          LottieAnimationManager.getAnimationPath(widget.selectedTheme);
    }

    // Update animation based on timer state change
    _updateAnimationState();
  }

  /// Initialize animation controllers.
  void _initializeControllers() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _updateAnimationState();
  }

  /// Update animation state based on timer state.
  void _updateAnimationState() {
    if (widget.timerState.isRunning) {
      // Start flame animation loop
      _flameController.repeat();
      _startProgressUpdate();
    } else {
      // Stop animations when timer is not running
      _flameController.stop();
      _progressUpdateTimer?.cancel();
    }
  }

  /// Start periodic updates to sync animation progress with timer progress.
  void _startProgressUpdate() {
    _progressUpdateTimer?.cancel();
    _progressUpdateTimer = Timer.periodic(Duration(milliseconds: 100), (_) {
      if (mounted && _composition != null) {
        // Map timer progress (0.0-1.0) to animation frame position
        final progress = widget.timerState.progress.clamp(0.0, 1.0);
        // Set controller to position within the animation based on timer progress
        // Add a small offset from the flame animation to create flickering around the progress point
        final flameOffset = (_flameController.value * 0.1) - 0.05; // ±0.05 offset
        final finalValue = (progress + flameOffset).clamp(0.0, 1.0);
        _animationController.value = finalValue;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      width: 300,
      child: Center(
        child: Lottie.asset(
          _currentAnimationPath,
          controller: _animationController,
          fit: BoxFit.contain,
          // Don't use auto-animate; we control via controllers
          animate: false,
          // When composition loads, store it for frame calculations
          onLoaded: (composition) {
            setState(() {
              _composition = composition;
            });
            _animationController.duration = composition.duration;
            // Update progress immediately after loading
            _updateAnimationState();
          },
          // Fallback UI if animation fails to load
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported, color: Colors.white30),
                    SizedBox(height: 8),
                    Text(
                      'Animation not found',
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _flameController.dispose();
    _progressUpdateTimer?.cancel();
    super.dispose();
  }
}

