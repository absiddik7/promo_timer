import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class SettingsProvider extends ChangeNotifier {
  late SettingsState _state;
  late SharedPreferences _prefs;

  SettingsProvider() {
    _state = SettingsState(
      soundEnabled: true,
      soundVolume: 0.2,
      keepScreenOn: true,
      hapticEnabled: true,
      selectedTheme: SensoryTheme.candle,
      defaultDurationMinutes: 25.0,
    );
  }

  SettingsState get state => _state;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadPreferences();
  }

  void _loadPreferences() {
    final soundEnabled = _prefs.getBool('soundEnabled') ?? true;
    // Read soundVolume defensively: older installs may have stored an int
    double soundVolume;
    final dynamic rawSound = _prefs.get('soundVolume');
    if (rawSound is double) {
      soundVolume = rawSound;
    } else if (rawSound is int) {
      soundVolume = rawSound.toDouble();
      // Migrate legacy int to double for future reads
      _prefs.setDouble('soundVolume', soundVolume);
    } else {
      soundVolume = 0.2;
    }
    final keepScreenOn = _prefs.getBool('keepScreenOn') ?? true;
    final hapticEnabled = _prefs.getBool('hapticEnabled') ?? true;
    final themeIndex = _prefs.getInt('selectedTheme') ?? 0;
    // Read stored default duration robustly: older installs may have stored
    // an `int` (via setInt). Try getDouble first, then fallback to getInt.
    double defaultDuration;
    final dynamic rawDefault = _prefs.get('defaultDurationMinutes');
    if (rawDefault is double) {
      defaultDuration = rawDefault;
    } else if (rawDefault is int) {
      defaultDuration = rawDefault.toDouble();
      // Migrate stored int to double so future getDouble won't throw
      _prefs.setDouble('defaultDurationMinutes', defaultDuration);
    } else {
      defaultDuration = 25.0;
    }

    _state = SettingsState(
      soundEnabled: soundEnabled,
      soundVolume: soundVolume,
      keepScreenOn: keepScreenOn,
      hapticEnabled: hapticEnabled,
      selectedTheme: SensoryTheme.values[themeIndex],
      defaultDurationMinutes: defaultDuration,
    );
    notifyListeners();
  }

  void setDefaultDuration(double minutes) {
    _state = _state.copyWith(defaultDurationMinutes: minutes);
    _prefs.setDouble('defaultDurationMinutes', minutes);
    notifyListeners();
  }

  void toggleSound() {
    _state = _state.copyWith(soundEnabled: !_state.soundEnabled);
    _prefs.setBool('soundEnabled', _state.soundEnabled);
    notifyListeners();
  }

  void setVolume(double volume) {
    _state = _state.copyWith(soundVolume: volume);
    _prefs.setDouble('soundVolume', volume);
    notifyListeners();
  }

  void toggleKeepScreenOn() {
    _state = _state.copyWith(keepScreenOn: !_state.keepScreenOn);
    _prefs.setBool('keepScreenOn', _state.keepScreenOn);
    notifyListeners();
  }

  void toggleHaptic() {
    _state = _state.copyWith(hapticEnabled: !_state.hapticEnabled);
    _prefs.setBool('hapticEnabled', _state.hapticEnabled);
    notifyListeners();
  }

  void setTheme(SensoryTheme theme) {
    _state = _state.copyWith(selectedTheme: theme);
    _prefs.setInt('selectedTheme', theme.index);
    notifyListeners();
  }
}
