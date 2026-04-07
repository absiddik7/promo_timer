import 'dart:math';

import 'package:flutter/foundation.dart';

class TimerFrameState {
  final bool hasStarted;
  final bool completedNow;
  final double meltProgress;

  const TimerFrameState({
    required this.hasStarted,
    required this.completedNow,
    required this.meltProgress,
  });
}

class TimerProvider extends ChangeNotifier {
  static const List<int> presetsMinutes = [1, 15, 25, 30, 45];

  int _selectedDurationMinutes = 25;
  DateTime? _timerStartTime;
  double _baseElapsedSeconds = 0.0;
  bool _isRunning = false;
  bool _isCompleted = false;
  int _remainingSeconds = 25 * 60;

  int get selectedDurationMinutes => _selectedDurationMinutes;
  bool get isRunning => _isRunning;
  bool get isCompleted => _isCompleted;
  int get remainingSeconds => _remainingSeconds;
  bool get hasStarted =>
      _isRunning || _remainingSeconds < _selectedDurationMinutes * 60;

  double get durationSeconds => _selectedDurationMinutes * 60.0;

  double meltProgressAt(DateTime now) =>
      (elapsedSecondsAt(now) / durationSeconds).clamp(0.0, 1.0);

  TimerFrameState computeFrameState(DateTime now) {
    if (!hasStarted) {
      return const TimerFrameState(
        hasStarted: false,
        completedNow: false,
        meltProgress: 0.0,
      );
    }

    final progress = meltProgressAt(now);
    final completedNow = tick(now);
    return TimerFrameState(
      hasStarted: true,
      completedNow: completedNow,
      meltProgress: completedNow ? 1.0 : progress,
    );
  }

  double elapsedSecondsAt(DateTime now) {
    if (!_isRunning || _timerStartTime == null) return _baseElapsedSeconds;
    final ms = now.difference(_timerStartTime!).inMilliseconds;
    return (_baseElapsedSeconds + ms / 1000.0).clamp(0.0, durationSeconds);
  }

  int remainingSecondsAt(DateTime now) {
    if (_isCompleted) return 0;
    return max(0, (durationSeconds - elapsedSecondsAt(now)).ceil());
  }

  bool tick(DateTime now) {
    bool completedNow = false;

    if (_isRunning) {
      final elapsed = elapsedSecondsAt(now);
      if (elapsed >= durationSeconds) {
        _baseElapsedSeconds = durationSeconds;
        _timerStartTime = null;
        _isRunning = false;
        _isCompleted = true;
        _remainingSeconds = 0;
        completedNow = true;
        notifyListeners();
        return completedNow;
      }
    }

    final currentRemaining = remainingSecondsAt(now);
    if (currentRemaining != _remainingSeconds) {
      _remainingSeconds = currentRemaining;
      notifyListeners();
    }

    return completedNow;
  }

  void setDurationMinutes(int minutes) {
    _selectedDurationMinutes = minutes;
    _baseElapsedSeconds = 0.0;
    _timerStartTime = null;
    _isRunning = false;
    _isCompleted = false;
    _remainingSeconds = minutes * 60;
    notifyListeners();
  }

  void reset() {
    _baseElapsedSeconds = 0.0;
    _timerStartTime = null;
    _isRunning = false;
    _isCompleted = false;
    _remainingSeconds = _selectedDurationMinutes * 60;
    notifyListeners();
  }

  void toggleRunPause(DateTime now) {
    if (_isCompleted) return;
    if (_isRunning) {
      _baseElapsedSeconds = elapsedSecondsAt(now);
      _timerStartTime = null;
      _isRunning = false;
    } else {
      _timerStartTime = now;
      _isRunning = true;
    }
    _remainingSeconds = remainingSecondsAt(now);
    notifyListeners();
  }

  static String formatRemainingTime(int totalSeconds) {
    final clamped = max(0, totalSeconds);
    final hours = clamped ~/ 3600;
    final minutes = (clamped % 3600) ~/ 60;
    final seconds = clamped % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
