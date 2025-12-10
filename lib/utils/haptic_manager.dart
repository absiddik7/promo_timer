import 'package:vibration/vibration.dart';

class HapticManager {
  static final HapticManager _instance = HapticManager._internal();

  factory HapticManager() {
    return _instance;
  }

  HapticManager._internal();

  Future<bool> canVibrate() async {
    return await Vibration.hasVibrator() ?? false;
  }

  Future<void> lightVibrate() async {
    if (await canVibrate()) {
      await Vibration.vibrate(duration: 50);
    }
  }

  Future<void> mediumVibrate() async {
    if (await canVibrate()) {
      await Vibration.vibrate(duration: 100);
    }
  }

  Future<void> heavyVibrate() async {
    if (await canVibrate()) {
      await Vibration.vibrate(duration: 200);
    }
  }

  Future<void> patternVibrate() async {
    if (await canVibrate()) {
      await Vibration.vibrate(
        pattern: [0, 100, 100, 100],
        intensities: [0, 200, 100, 200],
      );
    }
  }
}
