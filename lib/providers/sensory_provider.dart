import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';

class SensoryProvider extends ChangeNotifier {
  bool _isFullscreen = false;

  bool get isFullscreen => _isFullscreen;

  final Map<SensoryTheme, SensoryThemeConfig> themes = {
    SensoryTheme.candle: SensoryThemeConfig(
      theme: SensoryTheme.candle,
      displayName: 'Candle',
      description: 'A flickering flame that burns down as time passes',
      primaryColor: Color(0xFFFFB300),
      hasAudio: true,
    ),
    SensoryTheme.hourglass: SensoryThemeConfig(
      theme: SensoryTheme.hourglass,
      displayName: 'Hourglass',
      description: 'Sand flowing from top to bottom',
      primaryColor: Color(0xFFFFE082),
      hasAudio: true,
    ),
    SensoryTheme.waterGlass: SensoryThemeConfig(
      theme: SensoryTheme.waterGlass,
      displayName: 'Water Glass',
      description: 'Water filling a glass with gentle waves',
      primaryColor: Color(0xFF4FC3F7),
      hasAudio: true,
    ),
  };

  void enterFullscreen() {
    _isFullscreen = true;
    notifyListeners();
  }

  void exitFullscreen() {
    _isFullscreen = false;
    notifyListeners();
  }

  SensoryThemeConfig getThemeConfig(SensoryTheme theme) {
    return themes[theme]!;
  }
}
