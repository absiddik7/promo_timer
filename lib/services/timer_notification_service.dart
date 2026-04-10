import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

class TimerNotificationService {
  TimerNotificationService._();

  static final TimerNotificationService instance = TimerNotificationService._();

  static const int _timerRunningNotificationId = 12001;
  static const String _androidChannelId = 'timer_running_channel';
  static const String _androidChannelName = 'Timer Running';
  static const String _androidChannelDescription =
      'Shows a persistent notification while timer is running in background.';
  static const MethodChannel _androidCustomNotificationChannel = MethodChannel(
    'promo_timer/custom_notification',
  );
  static const String actionPause = 'timer_pause';
  static const String actionClose = 'timer_close';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _isPluginAvailable = true;
  Future<void> Function(String actionId)? _onActionSelected;

  Future<void> initialize({
    Future<void> Function(String actionId)? onActionSelected,
  }) async {
    _onActionSelected = onActionSelected;

    if (_isInitialized || kIsWeb) return;

    const androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInitSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: darwinInitSettings,
      macOS: darwinInitSettings,
    );

    try {
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );
    } on MissingPluginException {
      _isPluginAvailable = false;
      return;
    }

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    try {
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _androidChannelId,
          _androidChannelName,
          description: _androidChannelDescription,
          importance: Importance.low,
        ),
      );

      final iosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

      final macosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      await macosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
    } on MissingPluginException {
      _isPluginAvailable = false;
      return;
    }

    _isInitialized = true;
  }

  Future<void> showTimerRunningNotification({
    required int remainingSeconds,
    required bool isPaused,
  }) async {
    if (!_isInitialized ||
        !_isPluginAvailable ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final timeLabel = _formatRemainingTime(remainingSeconds);
    final clampedSeconds = remainingSeconds < 0 ? 0 : remainingSeconds;
    final secondaryLabel = isPaused
        ? 'Paused'
        : 'Ends ${_formatEndTime(DateTime.now().add(Duration(seconds: clampedSeconds)))}';
    final fallbackDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDescription,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        showWhen: false,
        category: AndroidNotificationCategory.service,
      ),
    );

    Future<void> showFallback() async {
      await _plugin.show(
        _timerRunningNotificationId,
        timeLabel,
        secondaryLabel,
        fallbackDetails,
        payload: 'open_app',
      );
    }

    try {
      await _androidCustomNotificationChannel.invokeMethod<void>(
        'showRunningTimerNotification',
        <String, Object>{
          'mainText': timeLabel,
          'secondaryText': secondaryLabel,
        },
      );
    } on MissingPluginException {
      try {
        await showFallback();
      } on MissingPluginException {
        _isPluginAvailable = false;
      }
    } on PlatformException {
      try {
        await showFallback();
      } on MissingPluginException {
        _isPluginAvailable = false;
      }
    }
  }

  Future<void> showTimerCompletedNotification() async {
    if (!_isInitialized ||
        !_isPluginAvailable ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final endedLabel = 'Session Ended ${_formatEndTime(DateTime.now())}';

    try {
      await _androidCustomNotificationChannel.invokeMethod<void>(
        'showCompletedTimerNotification',
        <String, Object>{
          'mainText': '',
          'secondaryText': endedLabel,
        },
      );
    } on PlatformException {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          ongoing: false,
          autoCancel: false,
          onlyAlertOnce: true,
          showWhen: false,
          category: AndroidNotificationCategory.alarm,
        ),
      );

      try {
        await _plugin.show(
          _timerRunningNotificationId,
          '',
          endedLabel,
          details,
          payload: 'open_app',
        );
      } on MissingPluginException {
        _isPluginAvailable = false;
      }
    } on MissingPluginException {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          ongoing: false,
          autoCancel: false,
          onlyAlertOnce: true,
          showWhen: false,
          category: AndroidNotificationCategory.alarm,
        ),
      );

      try {
        await _plugin.show(
          _timerRunningNotificationId,
          '',
          endedLabel,
          details,
          payload: 'open_app',
        );
      } on MissingPluginException {
        _isPluginAvailable = false;
      }
    }
  }

  Future<void> cancelTimerRunningNotification() async {
    if (!_isInitialized || !_isPluginAvailable || kIsWeb) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _androidCustomNotificationChannel.invokeMethod<void>(
          'cancelRunningTimerNotification',
        );
      }
      await _plugin.cancel(_timerRunningNotificationId);
    } on MissingPluginException {
      try {
        await _plugin.cancel(_timerRunningNotificationId);
      } on MissingPluginException {
        _isPluginAvailable = false;
      }
    } on PlatformException {
      try {
        await _plugin.cancel(_timerRunningNotificationId);
      } on MissingPluginException {
        _isPluginAvailable = false;
      }
    }
  }

  String _formatRemainingTime(int totalSeconds) {
    final clamped = totalSeconds < 0 ? 0 : totalSeconds;
    final hours = clamped ~/ 3600;
    final minutes = (clamped % 3600) ~/ 60;
    final seconds = clamped % 60;
    if (hours == 0) {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatEndTime(DateTime dateTime) {
    final hour24 = dateTime.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = hour24 >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $suffix';
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId;
    if (actionId == null || actionId.isEmpty) return;
    unawaited(_onActionSelected?.call(actionId));
  }
}
