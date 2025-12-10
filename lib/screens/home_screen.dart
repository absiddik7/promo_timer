import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/timer_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/sensory_provider.dart';
import '../widgets/candle_painter.dart';
import '../widgets/hourglass_painter.dart';
import '../widgets/water_glass_painter.dart';
import '../widgets/timer_display.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      body: Consumer3<TimerProvider, SettingsProvider, SensoryProvider>(
        builder: (context, timerProvider, settingsProvider, sensoryProvider, _) {
          return SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ZenFlow',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 2,
                            ),
                      ),
                      IconButton(
                        icon: Icon(Icons.settings, color: Colors.white70),
                        onPressed: () {
                          Navigator.of(context).pushNamed('/settings');
                        },
                      ),
                    ],
                  ),
                ),
                // Main visualization area
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Theme visualization
                        SizedBox(
                          height: 300,
                          width: 300,
                          child: _buildThemeVisualization(
                            timerProvider.state,
                            settingsProvider.state.selectedTheme,
                          ),
                        ),
                        SizedBox(height: 40),
                        // Timer display
                        TimerDisplay(
                          remainingSeconds: timerProvider.state.remainingSeconds,
                        ),
                        SizedBox(height: 40),
                        // Control buttons (icon-only)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!timerProvider.state.isRunning)
                              ElevatedButton(
                                onPressed: () {
                                  timerProvider.startTimer(settingsProvider.state.defaultDurationMinutes);
                                },
                                child: Icon(Icons.play_arrow),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white10,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              )
                            else
                              ElevatedButton(
                                onPressed: () {
                                  timerProvider.pauseTimer();
                                },
                                child: Icon(Icons.pause),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white10,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Reset timer and apply the user's default duration (icon-only)
                                timerProvider.resetTimer();
                                timerProvider.setDuration(settingsProvider.state.defaultDurationMinutes);
                              },
                              icon: Icon(Icons.refresh),
                              label: SizedBox.shrink(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white10,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Theme selector
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/themes');
                        },
                        child: Text(
                          'Change Theme',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeVisualization(TimerState timerState, SensoryTheme theme) {
    switch (theme) {
      case SensoryTheme.candle:
        return CustomPaint(
          painter: CandlePainter(
            progress: timerState.progress,
            flameAnimation: _animationController,
          ),
          size: Size.infinite,
        );
      case SensoryTheme.hourglass:
        return CustomPaint(
          painter: HourglassPainter(progress: timerState.progress),
          size: Size.infinite,
        );
      case SensoryTheme.waterGlass:
        return CustomPaint(
          painter: WaterGlassPainter(progress: timerState.progress),
          size: Size.infinite,
        );
    }
  }
}
