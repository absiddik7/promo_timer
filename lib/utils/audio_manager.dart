import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  late AudioPlayer _audioPlayer;
  double _volume = 0.2;

  factory AudioManager() {
    return _instance;
  }

  AudioManager._internal() {
    _audioPlayer = AudioPlayer();
  }

  Future<void> initialize() async {
    // Initialize audio player
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> playSound(String soundPath) async {
    try {
      await _audioPlayer.play(AssetSource(soundPath), volume: _volume);
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _audioPlayer.setVolume(_volume);
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
