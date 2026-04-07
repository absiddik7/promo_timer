import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VisualSettingsProvider extends ChangeNotifier {
  static const String _backgroundColorKey = 'demoBackgroundColor';
  static const String _candleColorKey = 'demoCandleColor';
  static const String _hapticOnTimerEndKey = 'hapticOnTimerEnd';

  Color _backgroundInnerColor = const Color(0xFF2A1A0A);
  Color _backgroundOuterColor = const Color(0xFF0A0604);
  Color _candleBodyColor = const Color(0xFFD4C4A0);
  bool _hapticOnTimerEnd = true;
  bool _isLoaded = false;

  Color get backgroundInnerColor => _backgroundInnerColor;
  Color get backgroundOuterColor => _backgroundOuterColor;
  Color get candleBodyColor => _candleBodyColor;
  bool get hapticOnTimerEnd => _hapticOnTimerEnd;

  Future<void> load() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final backgroundValue = prefs.getInt(_backgroundColorKey);
    if (backgroundValue != null) {
      _setBackgroundColor(Color(backgroundValue), persist: false, notify: false);
    }

    final candleValue = prefs.getInt(_candleColorKey);
    if (candleValue != null) {
      _setCandleColor(Color(candleValue), persist: false, notify: false);
    }

    final hapticValue = prefs.getBool(_hapticOnTimerEndKey);
    if (hapticValue != null) {
      _hapticOnTimerEnd = hapticValue;
    }

    _isLoaded = true;
    notifyListeners();
  }

  void setBackgroundColor(Color color) {
    _setBackgroundColor(color, persist: true, notify: true);
  }

  void setCandleColor(Color color) {
    _setCandleColor(color, persist: true, notify: true);
  }

  void setHapticOnTimerEnd(bool enabled) {
    _hapticOnTimerEnd = enabled;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(_hapticOnTimerEndKey, enabled);
    });
    notifyListeners();
  }

  void _setBackgroundColor(
    Color color, {
    required bool persist,
    required bool notify,
  }) {
    _backgroundInnerColor = color;
    _backgroundOuterColor = Color.lerp(color, Colors.black, 0.72) ?? color;
    if (persist) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt(_backgroundColorKey, color.toARGB32());
      });
    }
    if (notify) notifyListeners();
  }

  void _setCandleColor(
    Color color, {
    required bool persist,
    required bool notify,
  }) {
    _candleBodyColor = color;
    if (persist) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt(_candleColorKey, color.toARGB32());
      });
    }
    if (notify) notifyListeners();
  }
}
