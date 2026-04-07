import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/sound_settings_provider.dart';
import 'providers/candle_simulation_provider.dart';
import 'providers/timer_provider.dart';
import 'providers/visual_settings_provider.dart';
import 'screens/candle_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CandleSimulationProvider()),
          ChangeNotifierProvider(create: (_) => SoundSettingsProvider()),
          ChangeNotifierProvider(create: (_) => TimerProvider()),
          ChangeNotifierProvider(create: (_) => VisualSettingsProvider()),
        ],
        child: MaterialApp(
          title: 'Melting Candle',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(),
          home: const CandleScreen(),
        ),
      );
}
