import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';

class SessionControlsOverlay extends StatelessWidget {
  static const Duration _kOverlayAnimationDuration = Duration(
    milliseconds: 320,
  );
  static const double _kTimerFontSize = 52;
  static const double _kTimerLetterSpacing = 6;

  final bool visible;
  final bool isFullscreen;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenTimerPicker;
  final VoidCallback onReset;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onToggleFullscreen;

  const SessionControlsOverlay({
    super.key,
    required this.visible,
    required this.isFullscreen,
    required this.onOpenSettings,
    required this.onOpenTimerPicker,
    required this.onReset,
    required this.onTogglePlayPause,
    required this.onToggleFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: _kOverlayAnimationDuration,
        curve: Curves.easeOutCubic,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 0.05),
          duration: _kOverlayAnimationDuration,
          curve: Curves.easeOutCubic,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, right: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: isFullscreen
                          ? const SizedBox.shrink()
                          : _IconControlBtn(
                              icon: Icons.menu_rounded,
                              color: const Color(0xFFF5D080),
                              onTap: onOpenSettings,
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
                  padding: EdgeInsets.fromLTRB(
                    28,
                    isFullscreen ? 46 : 40,
                    28,
                    isFullscreen ? 60 : 52,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Consumer<TimerProvider>(
                        builder: (context, timerProvider, _) {
                          return GestureDetector(
                            onTap: onOpenTimerPicker,
                            child: Text(
                              TimerProvider.formatRemainingTime(
                                timerProvider.remainingSeconds,
                              ),
                              style: const TextStyle(
                                color: Color(0xFFF5D080),
                                fontSize: _kTimerFontSize,
                                letterSpacing: _kTimerLetterSpacing,
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
                            onTap: onReset,
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
                                onTap: onTogglePlayPause,
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          _IconControlBtn(
                            icon: isFullscreen
                                ? Icons.fullscreen_exit_rounded
                                : Icons.fullscreen_rounded,
                            color: const Color(0xFFF5D080),
                            onTap: onToggleFullscreen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
