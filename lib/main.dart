import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/candle_simulation_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/premium_provider.dart';
import 'providers/sound_settings_provider.dart';
import 'providers/timer_provider.dart';
import 'providers/visual_settings_provider.dart';
import 'screens/candle_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'services/timer_notification_service.dart';
import 'package:vibration/vibration.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => CandleSimulationProvider()),
      ChangeNotifierProvider(create: (_) => OnboardingProvider()),
      ChangeNotifierProvider(create: (_) => PremiumProvider()),
      ChangeNotifierProvider(create: (_) => SoundSettingsProvider()),
      ChangeNotifierProvider(create: (_) => TimerProvider()),
      ChangeNotifierProvider(create: (_) => VisualSettingsProvider()),
    ],
    child: const _AppShell(),
  );
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> with WidgetsBindingObserver {
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  TimerProvider? _timerProvider;
  SoundSettingsProvider? _audioSettingsProvider;
  CandleSimulationProvider? _candleSimulationProvider;
  VisualSettingsProvider? _visualSettingsProvider;
  OnboardingProvider? _onboardingProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize onboarding provider
    _onboardingProvider = context.read<OnboardingProvider>();
    if (!_onboardingProvider!.isInitialized) {
      unawaited(_onboardingProvider!.init());
    }

    final timerProvider = context.read<TimerProvider>();
    if (!identical(_timerProvider, timerProvider)) {
      _timerProvider?.removeListener(_handleTimerChanged);
      _timerProvider = timerProvider;
      _timerProvider?.addListener(_handleTimerChanged);
    }

    _audioSettingsProvider = context.read<SoundSettingsProvider>();
    _candleSimulationProvider = context.read<CandleSimulationProvider>();
    _visualSettingsProvider = context.read<VisualSettingsProvider>();

    unawaited(
      TimerNotificationService.instance.initialize(
        onActionSelected: _handleNotificationAction,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timerProvider?.removeListener(_handleTimerChanged);
    unawaited(
      TimerNotificationService.instance.cancelTimerRunningNotification(),
    );
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    unawaited(_syncTimerNotificationForLifecycle());

    if (state == AppLifecycleState.detached) {
      _timerProvider?.stopForAppTermination();
      unawaited(
        TimerNotificationService.instance.cancelTimerRunningNotification(),
      );
    }
  }

  void _handleTimerChanged() {
    final timerProvider = _timerProvider;
    if (timerProvider == null) return;

    if (timerProvider.consumeCompletionEvent()) {
      unawaited(_handleTimerCompleted());
      return;
    }

    unawaited(_syncTimerNotificationForLifecycle());
  }

  Future<void> _handleNotificationAction(String actionId) async {
    final timerProvider = _timerProvider;
    if (timerProvider == null) return;

    if (actionId == TimerNotificationService.actionPause) {
      if (timerProvider.isRunning) {
        timerProvider.toggleRunPause(DateTime.now());
        await _audioSettingsProvider?.setTimerActive(false);
      } else if (timerProvider.hasStarted && !timerProvider.isCompleted) {
        timerProvider.toggleRunPause(DateTime.now());
        if (timerProvider.isRunning) {
          await _audioSettingsProvider?.setTimerActive(true);
          _candleSimulationProvider?.relightIfNeeded();
        }
      }
    } else if (actionId == TimerNotificationService.actionClose) {
      timerProvider.stopForAppTermination();
      await _audioSettingsProvider?.setTimerActive(false);
      _candleSimulationProvider?.reset();
      await TimerNotificationService.instance.cancelTimerRunningNotification();
    }

    await _syncTimerNotificationForLifecycle();
  }

  Future<void> _handleTimerCompleted() async {
    await _audioSettingsProvider?.setTimerActive(false);
    await _audioSettingsProvider?.playTimerFinishedSound();
    _candleSimulationProvider?.completeAndBlowOut();
    await _vibrateOnTimerEnd();
    await TimerNotificationService.instance.showTimerCompletedNotification();
  }

  Future<void> _syncTimerNotificationForLifecycle() async {
    final timerProvider = _timerProvider;
    if (timerProvider == null) return;

    if (_lifecycleState == AppLifecycleState.resumed) {
      await TimerNotificationService.instance.cancelTimerRunningNotification();
      return;
    }

    final isBackground =
        _lifecycleState == AppLifecycleState.paused ||
        _lifecycleState == AppLifecycleState.hidden;

    if (!isBackground) {
      await TimerNotificationService.instance.cancelTimerRunningNotification();
      return;
    }

    if (timerProvider.isCompleted) {
      await TimerNotificationService.instance.showTimerCompletedNotification();
      return;
    }

    if (timerProvider.isRunning) {
      await TimerNotificationService.instance.showTimerRunningNotification(
        remainingSeconds: timerProvider.remainingSeconds,
        isPaused: false,
      );
      return;
    }

    if (timerProvider.hasStarted) {
      await TimerNotificationService.instance.showTimerRunningNotification(
        remainingSeconds: timerProvider.remainingSeconds,
        isPaused: true,
      );
      return;
    }

    await TimerNotificationService.instance.cancelTimerRunningNotification();
  }

  Future<void> _vibrateOnTimerEnd() async {
    if (_visualSettingsProvider == null ||
        !_visualSettingsProvider!.hapticOnTimerEnd) {
      return;
    }

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        await Vibration.vibrate(duration: 500, amplitude: 255);
      } else {
        HapticFeedback.heavyImpact();
      }
    } catch (_) {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Candle Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Consumer<OnboardingProvider>(
        builder: (context, onboarding, _) {
          // Wait for initialization or show onboarding if not complete
          if (!onboarding.isInitialized) {
            return const Scaffold(
              backgroundColor: Color(0xFF0F1320),
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!onboarding.onboardingComplete) {
            return OnboardingFlow(
              onComplete: () {
                // This will trigger a rebuild when onboarding is complete
              },
            );
          }

          return const CandleScreen();
        },
      ),
    );
  }
}
