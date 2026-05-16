import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundTrackOption {
  final String label;
  final String assetPath;
  final String imageAssetPath;

  const SoundTrackOption({
    required this.label,
    required this.assetPath,
    required this.imageAssetPath,
  });
}

class SoundSettingsProvider extends ChangeNotifier {
  static const String _enabledKey = 'soundEnabled';
  static const String _trackIndexKey = 'soundTrackIndex';
  static const String _volumeKey = 'soundVolume';
  static const String _timerFinishedSoundAsset = 'audio/timer-end-sound.mp3';

  static const List<SoundTrackOption> _tracks = [
    SoundTrackOption(
      label: 'Candle burning',
      assetPath: 'audio/candle-burning-sound-1.mp3',
      imageAssetPath: 'assets/icons/candle_icon.svg',
    ),
    SoundTrackOption(
      label: 'Rain',
      assetPath: 'audio/rain-sound.mp3',
      imageAssetPath: 'assets/icons/rain_icon.svg',
    ),
    SoundTrackOption(
      label: 'Night',
      assetPath: 'audio/night-sound.mp3',
      imageAssetPath: 'assets/icons/night_icon.svg',
    ),
    SoundTrackOption(
      label: 'Keyboard typing',
      assetPath: 'audio/keyboard-typing-sound.mp3',
      imageAssetPath: 'assets/icons/keyboard_icon.svg',
    ),
  ];

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _completionPlayer = AudioPlayer();
  Timer? _completionCutoffTimer;

  bool _isLoaded = false;
  bool _isEnabled = true;
  bool _timerActive = false;
  bool _isPlaying = false;
  bool _isPreviewing = false;
  int _selectedTrackIndex = 0;
  int? _currentPlaybackTrackIndex;
  double _volume = 1.0;

  SoundSettingsProvider() {
    unawaited(load());
  }

  List<SoundTrackOption> get availableTracks => _tracks;
  bool get isEnabled => _isEnabled;
  bool get isPlaying => _isPlaying;
  bool get isPreviewing => _isPreviewing;
  double get volume => _volume;
  int get selectedTrackIndex => _selectedTrackIndex;
  int? get currentPlaybackTrackIndex => _currentPlaybackTrackIndex;
  SoundTrackOption get selectedTrack => _tracks[_selectedTrackIndex];
  String get selectedTrackLabel => selectedTrack.label;

  Future<void> load() async {
    if (_isLoaded) return;

    final prefs = await SharedPreferences.getInstance();

    _isEnabled = prefs.getBool(_enabledKey) ?? true;

    final storedTrackIndex = prefs.getInt(_trackIndexKey) ?? 0;
    _selectedTrackIndex = storedTrackIndex.clamp(0, _tracks.length - 1);

    _volume = (prefs.getDouble(_volumeKey) ?? 1.0).clamp(0.0, 1.0);

    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(_volume);
    await _completionPlayer.setReleaseMode(ReleaseMode.release);
    await _completionPlayer.setVolume(_volume);

    _isLoaded = true;
    notifyListeners();

    if (_timerActive && _isEnabled) {
      await _startPlayback(restart: true);
    }
  }

  Future<void> setTimerActive(bool active) async {
    _timerActive = active;

    if (!_timerActive) {
      await _stopPlayback();
      _isPreviewing = false;
      notifyListeners();
      return;
    }

    if (!_isLoaded) return;

    if (_isEnabled) {
      _isPreviewing = false;
      await _startPlayback(restart: true);
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);

    if (!_isLoaded) {
      notifyListeners();
      return;
    }

    if (!_isEnabled) {
      await _stopPlayback();
      _completionCutoffTimer?.cancel();
      await _completionPlayer.stop();
    } else if (_timerActive) {
      _isPreviewing = false;
      await _startPlayback(restart: true);
    }

    notifyListeners();
  }

  Future<void> setSelectedTrackIndex(int index) async {
    if (index < 0 || index >= _tracks.length) return;
    if (index == _selectedTrackIndex) return;

    _selectedTrackIndex = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_trackIndexKey, index);

    if (!_isLoaded) {
      notifyListeners();
      return;
    }

    if (_timerActive && _isEnabled) {
      _isPreviewing = false;
      await _startPlayback(restart: true);
    }

    notifyListeners();
  }

  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, _volume);

    if (!_isLoaded) {
      notifyListeners();
      return;
    }

    if (_isPlaying) {
      await _player.setVolume(_volume);
    }
    await _completionPlayer.setVolume(_volume);

    notifyListeners();
  }

  Future<void> playTimerFinishedSound() async {
    if (!_isLoaded || !_isEnabled) return;

    try {
      _completionCutoffTimer?.cancel();
      await _completionPlayer.stop();
      await _completionPlayer.setVolume(_volume);
      await _completionPlayer.play(AssetSource(_timerFinishedSoundAsset));

      // Use a short cue so completion feedback is noticeable but not intrusive.
      _completionCutoffTimer = Timer(const Duration(seconds: 3), () {
        unawaited(_completionPlayer.stop());
      });
    } catch (_) {
      // Swallow playback failures so timer completion flow is never interrupted.
    }
  }

  Future<void> _startPlayback({
    required bool restart,
    int? trackIndexOverride,
    bool allowWhenTimerInactive = false,
  }) async {
    if (!_isEnabled || (!_timerActive && !allowWhenTimerInactive)) return;
    final trackIndex = trackIndexOverride ?? _selectedTrackIndex;
    if (trackIndex < 0 || trackIndex >= _tracks.length) return;

    try {
      if (restart) {
        await _player.stop();
      }
      await _player.setVolume(_volume);
      await _player.play(AssetSource(_tracks[trackIndex].assetPath));
      _isPlaying = true;
      _currentPlaybackTrackIndex = trackIndex;
    } catch (_) {
      _isPlaying = false;
      _currentPlaybackTrackIndex = null;
    }

    notifyListeners();
  }

  Future<void> _stopPlayback() async {
    if (_isPlaying) {
      await _player.stop();
    }
    _isPlaying = false;
    _currentPlaybackTrackIndex = null;
    notifyListeners();
  }

  bool isTrackPlaying(int index) {
    return _isPlaying && _currentPlaybackTrackIndex == index;
  }

  Future<void> toggleTrackPreview(int index) async {
    if (!_isLoaded || !_isEnabled) return;
    if (index < 0 || index >= _tracks.length) return;

    if (_isPreviewing && isTrackPlaying(index)) {
      await stopPreviewPlayback();
      return;
    }

    _isPreviewing = true;
    await _startPlayback(
      restart: true,
      trackIndexOverride: index,
      allowWhenTimerInactive: true,
    );
  }

  Future<void> stopPreviewPlayback() async {
    if (!_isPreviewing) return;
    _isPreviewing = false;
    await _stopPlayback();
  }

  @override
  void dispose() {
    _completionCutoffTimer?.cancel();
    unawaited(_player.dispose());
    unawaited(_completionPlayer.dispose());
    super.dispose();
  }
}
