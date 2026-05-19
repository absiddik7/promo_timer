class SoundPreset {
  final String label;
  final String assetPath;
  final String imageAssetPath;
  final bool isPremium;

  const SoundPreset({
    required this.label,
    required this.assetPath,
    required this.imageAssetPath,
    required this.isPremium,
  });
}

class SoundPresets {
  static const List<SoundPreset> tracks = [
    SoundPreset(
      label: 'Candle burning',
      assetPath: 'audio/candle-burning-sound-1.mp3',
      imageAssetPath: 'assets/icons/candle_icon.svg',
      isPremium: false,
    ),
    SoundPreset(
      label: 'Rain',
      assetPath: 'audio/rain-sound.mp3',
      imageAssetPath: 'assets/icons/rain_icon.svg',
      isPremium: true,
    ),
    SoundPreset(
      label: 'Night',
      assetPath: 'audio/night-sound.mp3',
      imageAssetPath: 'assets/icons/night_icon.svg',
      isPremium: true,
    ),
    SoundPreset(
      label: 'Keyboard typing',
      assetPath: 'audio/keyboard-typing-sound.mp3',
      imageAssetPath: 'assets/icons/keyboard_icon.svg',
      isPremium: true,
    ),
  ];

  static List<SoundPreset> get freeTracks =>
      tracks.where((track) => !track.isPremium).toList(growable: false);
}
