import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/timer_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/timer_display.dart';
import '../widgets/lottie_timer_animation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isFullscreen = false;
  bool _showOverlayControls = true;
  Timer? _overlayHideTimer;

  @override
  void initState() {
    super.initState();
  }

  void _showControlsTemporarily() {
    if (!_isFullscreen) return;
    _overlayHideTimer?.cancel();
    setState(() {
      _showOverlayControls = true;
    });
    _overlayHideTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || !_isFullscreen) return;
      setState(() {
        _showOverlayControls = false;
      });
    });
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      _showOverlayControls = true;
    });
    if (_isFullscreen) {
      _showControlsTemporarily();
    } else {
      _overlayHideTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _overlayHideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      body: Consumer2<TimerProvider, SettingsProvider>(
        builder: (context, timerProvider, settingsProvider, _) {
          final bool showOverlay = !_isFullscreen || _showOverlayControls;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _isFullscreen ? _showControlsTemporarily : null,
            child: SafeArea(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: SizedBox(
                      height: _isFullscreen ? double.infinity : 300,
                      width: _isFullscreen ? double.infinity : 300,
                      child: _buildThemeVisualization(
                        timerProvider.state,
                        settingsProvider.state.selectedTheme,
                      ),
                    ),
                  ),
                  if (showOverlay)
                    Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 8, right: 8, left: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_isFullscreen)
                                _buildControlIconButton(
                                  icon: Icons.fullscreen_exit,
                                  onPressed: _toggleFullscreen,
                                )
                              else
                                SizedBox(width: 44),
                              _buildControlIconButton(
                                icon: Icons.menu_rounded,
                                onPressed: () {
                                  Navigator.of(context).pushNamed('/settings');
                                },
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        if (!_isFullscreen) ...[
                          TimerDisplay(
                            remainingSeconds:
                                timerProvider.state.remainingSeconds,
                          ),
                          SizedBox(height: 40),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildControlIconButton(
                              icon: timerProvider.state.isRunning
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              onPressed: () {
                                if (timerProvider.state.isRunning) {
                                  timerProvider.pauseTimer();
                                } else {
                                  timerProvider.startTimer(
                                    settingsProvider
                                        .state
                                        .defaultDurationMinutes,
                                  );
                                }
                                _showControlsTemporarily();
                              },
                            ),
                            SizedBox(width: 16),
                            _buildControlIconButton(
                              icon: Icons.refresh,
                              onPressed: () {
                                timerProvider.resetTimer();
                                timerProvider.setDuration(
                                  settingsProvider.state.defaultDurationMinutes,
                                );
                                _showControlsTemporarily();
                              },
                            ),
                            SizedBox(width: 16),
                            _buildControlIconButton(
                              icon: _isFullscreen
                                  ? Icons.fullscreen_exit
                                  : Icons.fullscreen,
                              onPressed: _toggleFullscreen,
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white10,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildThemeVisualization(TimerState timerState, SensoryTheme theme) {
    /// Use Lottie-based animation widget that syncs with timer progress.
    /// Timer progress (0.0-1.0) controls animation position via LottieController.
    return LottieTimerAnimation(
      timerState: timerState,
      selectedTheme: theme,
    );
  }
}
