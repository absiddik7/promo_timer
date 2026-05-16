import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingProvider extends ChangeNotifier {
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _focusAreaKey = 'survey_focus_area';
  static const String _distractionKey = 'survey_distraction';
  static const String _sessionDurationKey = 'survey_session_duration';
  static const String _soundPreferenceKey = 'survey_sound_preference';

  late SharedPreferences _prefs;
  bool _isInitialized = false;
  bool _onboardingComplete = false;

  // Survey answers
  String? _focusArea;
  String? _distraction;
  int? _sessionDuration; // in minutes
  String? _soundPreference;

  bool get isInitialized => _isInitialized;
  bool get onboardingComplete => _onboardingComplete;
  String? get focusArea => _focusArea;
  String? get distraction => _distraction;
  int? get sessionDuration => _sessionDuration;
  String? get soundPreference => _soundPreference;

  Future<void> init() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    _onboardingComplete = _prefs.getBool(_onboardingCompleteKey) ?? false;
    _focusArea = _prefs.getString(_focusAreaKey);
    _distraction = _prefs.getString(_distractionKey);
    _sessionDuration = _prefs.getInt(_sessionDurationKey);
    _soundPreference = _prefs.getString(_soundPreferenceKey);

    _isInitialized = true;
    notifyListeners();
  }

  void setFocusArea(String area) {
    _focusArea = area;
    _prefs.setString(_focusAreaKey, area);
    notifyListeners();
  }

  void setDistraction(String distraction) {
    _distraction = distraction;
    _prefs.setString(_distractionKey, distraction);
    notifyListeners();
  }

  void setSessionDuration(int minutes) {
    _sessionDuration = minutes;
    _prefs.setInt(_sessionDurationKey, minutes);
    notifyListeners();
  }

  void setSoundPreference(String sound) {
    _soundPreference = sound;
    _prefs.setString(_soundPreferenceKey, sound);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _onboardingComplete = true;
    await _prefs.setBool(_onboardingCompleteKey, true);
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    _onboardingComplete = false;
    _focusArea = null;
    _distraction = null;
    _sessionDuration = null;
    _soundPreference = null;

    await _prefs.remove(_onboardingCompleteKey);
    await _prefs.remove(_focusAreaKey);
    await _prefs.remove(_distractionKey);
    await _prefs.remove(_sessionDurationKey);
    await _prefs.remove(_soundPreferenceKey);

    notifyListeners();
  }
}
