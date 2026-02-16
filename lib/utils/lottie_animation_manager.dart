/// Utility to manage Lottie animation resources for different timer themes.
/// Maps SensoryTheme to animation JSON file paths and provides loading helpers.

import '../models/models.dart';

class LottieAnimationManager {
  /// Maps each sensory theme to its corresponding Lottie animation JSON file.
  static const Map<SensoryTheme, String> themeAnimationMap = {
    SensoryTheme.candle: 'assets/animations/candle.json',
  };

  /// Gets the animation file path for a given theme.
  /// 
  /// Returns the relative asset path for the Lottie animation JSON file.
  static String getAnimationPath(SensoryTheme theme) {
    return themeAnimationMap[theme] ?? themeAnimationMap[SensoryTheme.candle]!;
  }

  /// Gets all available animation themes.
  static List<SensoryTheme> getAvailableThemes() {
    return [SensoryTheme.candle];
  }

  /// Checks if a theme has a corresponding animation file.
  static bool hasAnimation(SensoryTheme theme) {
    return theme == SensoryTheme.candle;
  }
}
