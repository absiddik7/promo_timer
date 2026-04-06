import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

part 'candle_screen_part.dart';
part 'menu_settings_screen_part.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Melting Candle',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: const CandleScreen(),
      );
}
