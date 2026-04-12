import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../styles/settings_palette.dart';
import '../widgets/timer_bottom_sheets.dart';

class TimerSettingsScreen extends StatefulWidget {
  const TimerSettingsScreen({super.key});

  @override
  State<TimerSettingsScreen> createState() => _TimerSettingsScreenState();
}

class _TimerSettingsScreenState extends State<TimerSettingsScreen> {
  Future<void> _createPresetDuration(TimerProvider timerProvider) async {
    final customMinutes = await TimerBottomSheets.showCustomTimerDialer(
      context,
      initialMinutes: timerProvider.selectedDurationMinutes,
    );
    if (!mounted || customMinutes == null) return;
    await context.read<TimerProvider>().addPresetMinutes(customMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = context.watch<TimerProvider>();

    return Scaffold(
      backgroundColor: SettingsPalette.canvas,
      appBar: AppBar(
        backgroundColor: SettingsPalette.canvas,
        surfaceTintColor: SettingsPalette.canvas,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Timer',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
      ),
      body: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0, end: 1),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 20),
              child: child,
            ),
          );
        },
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'Default Duration',
              style: TextStyle(
                color: SettingsPalette.textMuted,
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: timerProvider.presetMinutes.map((minutes) {
                final isSelected =
                    minutes == timerProvider.selectedDurationMinutes;
                return GestureDetector(
                  onTap: () =>
                      context.read<TimerProvider>().setDurationMinutes(minutes),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFF5D080)
                            : SettingsPalette.stroke,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          SettingsPalette.panelStart,
                          SettingsPalette.panelEnd,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_rounded,
                          color: SettingsPalette.icon,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          TimerProvider.formatDurationLabel(minutes),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_rounded,
                            color: Color(0xFFF5D080),
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _createPresetDuration(timerProvider),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: SettingsPalette.stroke),
                  foregroundColor: SettingsPalette.icon,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_alarm_rounded),
                label: const Text(
                  'Create preset duration',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
