import 'package:flutter/material.dart';

class TimerDisplay extends StatelessWidget {
  final int remainingSeconds;

  const TimerDisplay({
    Key? key,
    required this.remainingSeconds,
  }) : super(key: key);

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatTime(remainingSeconds),
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
    );
  }
}
