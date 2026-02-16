// Enum for sensory themes
import 'dart:ui';

enum SensoryTheme {
  candle,
}

// Timer state model
class TimerState {
  final double duration; // in minutes (can be fractional, e.g. 0.5 = 30s)
  final int remainingSeconds;
  final bool isRunning;
  final bool isCompleted;
  final double progress; // 0.0 to 1.0

  TimerState({
    required this.duration,
    required this.remainingSeconds,
    required this.isRunning,
    required this.isCompleted,
    required this.progress,
  });

  TimerState copyWith({
    double? duration,
    int? remainingSeconds,
    bool? isRunning,
    bool? isCompleted,
    double? progress,
  }) {
    return TimerState(
      duration: duration ?? this.duration,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      isCompleted: isCompleted ?? this.isCompleted,
      progress: progress ?? this.progress,
    );
  }
}

// Sensory theme configuration
class SensoryThemeConfig {
  final SensoryTheme theme;
  final String displayName;
  final String description;
  final Color primaryColor;
  final bool hasAudio;

  SensoryThemeConfig({
    required this.theme,
    required this.displayName,
    required this.description,
    required this.primaryColor,
    required this.hasAudio,
  });
}

// Settings state model
class SettingsState {
  final bool soundEnabled;
  final double soundVolume; // 0.0 to 1.0
  final bool keepScreenOn;
  final bool hapticEnabled;
  final SensoryTheme selectedTheme;
  final double defaultDurationMinutes;

  SettingsState({
    required this.soundEnabled,
    required this.soundVolume,
    required this.keepScreenOn,
    required this.hapticEnabled,
    required this.selectedTheme,
    required this.defaultDurationMinutes,
  });

  SettingsState copyWith({
    bool? soundEnabled,
    double? soundVolume,
    bool? keepScreenOn,
    bool? hapticEnabled,
    SensoryTheme? selectedTheme,
    double? defaultDurationMinutes,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      soundVolume: soundVolume ?? this.soundVolume,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      defaultDurationMinutes: defaultDurationMinutes ?? this.defaultDurationMinutes,
    );
  }
}

// Import Color

