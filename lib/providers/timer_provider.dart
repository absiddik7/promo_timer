import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class TimerProvider extends ChangeNotifier {
  late TimerState _state;
  Timer? _timer;

  TimerProvider() {
    _state = TimerState(
      duration: 25.0,
      remainingSeconds: (25.0 * 60).round(),
      isRunning: false,
      isCompleted: false,
      progress: 0.0,
    );
  }

  TimerState get state => _state;

  void startTimer(double minutes) {
    final secs = (minutes * 60).round();
    _state = _state.copyWith(
      duration: minutes,
      remainingSeconds: secs,
      isRunning: true,
      isCompleted: false,
      progress: 0.0,
    );
    _startCountdown();
    notifyListeners();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_state.remainingSeconds > 0) {
        final newRemaining = _state.remainingSeconds - 1;
        final denom = (_state.duration * 60);
        final newProgress = denom > 0 ? 1.0 - (newRemaining / denom) : 0.0;
        
        _state = _state.copyWith(
          remainingSeconds: newRemaining,
          progress: newProgress,
        );
        notifyListeners();

        if (newRemaining == 0) {
          completeTimer();
        }
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    _state = _state.copyWith(isRunning: false);
    notifyListeners();
  }

  void resumeTimer() {
    if (!_state.isRunning && _state.remainingSeconds > 0) {
      _state = _state.copyWith(isRunning: true);
      _startCountdown();
      notifyListeners();
    }
  }

  void resetTimer() {
    _timer?.cancel();
    _state = TimerState(
      duration: 25.0,
      remainingSeconds: (25.0 * 60).round(),
      isRunning: false,
      isCompleted: false,
      progress: 0.0,
    );
    notifyListeners();
  }

  void completeTimer() {
    _timer?.cancel();
    _state = _state.copyWith(
      isRunning: false,
      isCompleted: true,
      progress: 1.0,
    );
    notifyListeners();
  }

  void setDuration(double minutes) {
    if (!_state.isRunning) {
      final secs = (minutes * 60).round();
      _state = _state.copyWith(
        duration: minutes,
        remainingSeconds: secs,
        progress: 0.0,
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
