import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// Manages timer state and orchestrates timer operations.
/// 
/// This provider maintains timer progress as a value between 0.0 (start) and 1.0 (complete).
/// The progress value is directly used by Lottie animations to control animation progress,
/// not animation playback speed. This creates a precise visual representation of remaining time.
/// 
/// Supported operations:
/// - startTimer: Start a new timer with specified duration in minutes
/// - pauseTimer: Temporarily pause the running timer
/// - resumeTimer: Resume a paused timer (maintains remaining seconds)
/// - resetTimer: Reset timer to initial state
/// - setDuration: Change timer duration (only when not running)
/// 
/// The timer updates progress continuously as time elapses, triggering UI updates
/// via notifyListeners() to update Lottie animation progress in real-time.

class TimerProvider extends ChangeNotifier {
  late TimerState _state;
  Timer? _timer;

  TimerProvider() {
    _state = TimerState(
      duration: 1.0,
      remainingSeconds: (1.0 * 60).round(),
      isRunning: false,
      isCompleted: false,
      progress: 0.0,
    );
  }

  TimerState get state => _state;

  /// Start a new timer with the specified duration in minutes.
  /// Resets progress to 0.0 and begins the countdown.
  /// 
  /// Parameters:
  ///   minutes: Duration of the timer in minutes (supports decimal values like 1.5)
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

  /// Internal method that drives the countdown and progress updates.
  /// 
  /// Decrements remaining seconds and calculates progress (0.0-1.0) every second.
  /// Progress is used directly by LottieTimerAnimation to show animation position.
  /// Calls completeTimer() when countdown reaches zero.
  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_state.remainingSeconds > 0) {
        final newRemaining = _state.remainingSeconds - 1;
        final denom = (_state.duration * 60);
        
        // Calculate progress: maps elapsed time to 0.0-1.0 range
        // This single value controls Lottie animation progress in LottieTimerAnimation
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

  /// Pause the currently running timer.
  /// Preserves remaining seconds and progress for later resumption.
  void pauseTimer() {
    _timer?.cancel();
    _state = _state.copyWith(isRunning: false);
    notifyListeners();
  }

  /// Resume a paused timer.
  /// Only works if timer is paused and has remaining time.
  void resumeTimer() {
    if (!_state.isRunning && _state.remainingSeconds > 0) {
      _state = _state.copyWith(isRunning: true);
      _startCountdown();
      notifyListeners();
    }
  }

  /// Reset timer to its initial state (25 minutes, progress 0.0).
  void resetTimer() {
    _timer?.cancel();
    _state = TimerState(
      duration: 1.0,
      remainingSeconds: (1.0 * 60).round(),
      isRunning: false,
      isCompleted: false,
      progress: 0.0,
    );
    notifyListeners();
  }

  /// Mark timer as completed.
  /// Sets progress to 1.0 to show full animation completion.
  void completeTimer() {
    _timer?.cancel();
    _state = _state.copyWith(
      isRunning: false,
      isCompleted: true,
      progress: 1.0,
    );
    notifyListeners();
  }

  /// Set a new timer duration without starting.
  /// Only allowed when timer is not running.
  /// 
  /// Parameters:
  ///   minutes: New duration in minutes
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

