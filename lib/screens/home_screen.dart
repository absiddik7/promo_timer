import 'package:flutter/material.dart';
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
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      body: Consumer2<TimerProvider, SettingsProvider>(
        builder: (context, timerProvider, settingsProvider, _) {
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
                SizedBox(height: 16),
              ],
            ),
          );
        },
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
