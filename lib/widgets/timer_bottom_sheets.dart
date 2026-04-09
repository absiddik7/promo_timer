import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../providers/timer_provider.dart';
import '../styles/settings_palette.dart';

class TimerBottomSheets {
  const TimerBottomSheets._();

  static Future<int?> showCustomTimerDialer(
    BuildContext context, {
    required int initialMinutes,
  }) async {
    int tempMinutes = initialMinutes;
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SettingsPalette.panelStart,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final selectedLabel = TimerProvider.formatDurationLabel(
              tempMinutes,
            );

            return _buildSheetContainer(
              context: context,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _SheetHeader(
                        title: 'Custom Timer',
                        subtitle: 'Choose an exact duration',
                      ),
                      const Spacer(),
                      _SelectionBadge(label: selectedLabel),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 182,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: SettingsPalette.stroke),
                      color: const Color(0xB3121A29),
                    ),
                    child: CupertinoTheme(
                      data: const CupertinoThemeData(
                        brightness: Brightness.dark,
                        primaryColor: SettingsPalette.icon,
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      child: CupertinoTimerPicker(
                        mode: CupertinoTimerPickerMode.hm,
                        initialTimerDuration: Duration(minutes: tempMinutes),
                        onTimerDurationChanged: (duration) {
                          final nextMinutes = max(1, duration.inMinutes);
                          setSheetState(() {
                            tempMinutes = nextMinutes;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: SettingsPalette.stroke,
                            ),
                            foregroundColor: SettingsPalette.textMuted,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.of(context).pop(tempMinutes),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SettingsPalette.icon,
                            foregroundColor: const Color(0xFF101722),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Future<int?> showTimerPresetPicker(
    BuildContext context, {
    required int selectedDurationMinutes,
    required List<int> presetMinutes,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SettingsPalette.panelStart,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (context) {
        return _buildSheetContainer(
          context: context,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHeader(
                title: 'Set Timer',
                subtitle: 'Pick a quick duration or choose custom',
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: presetMinutes.map((m) {
                  final isSelected = m == selectedDurationMinutes;
                  return _PresetChip(
                    minutes: m,
                    isSelected: isSelected,
                    onTap: () => Navigator.of(context).pop(m),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(-1),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: SettingsPalette.stroke),
                    foregroundColor: SettingsPalette.icon,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text(
                    'Set custom time',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget _buildSheetContainer({
  required BuildContext context,
  required Widget child,
}) {
  final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

  return Container(
    width: double.infinity,
    padding: EdgeInsets.fromLTRB(16, 10, 16, 18 + bottomInset),
    decoration: const BoxDecoration(
      color: SettingsPalette.panelStart,
      border: Border(top: BorderSide(color: SettingsPalette.stroke)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SheetHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: SettingsPalette.textMuted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _SelectionBadge extends StatelessWidget {
  final String label;

  const _SelectionBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: SettingsPalette.icon.withValues(alpha: 0.12),
        border: Border.all(color: SettingsPalette.stroke),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: SettingsPalette.icon,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final int minutes;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.minutes,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected
              ? SettingsPalette.icon
              : SettingsPalette.icon.withValues(alpha: 0.08),
          border: Border.all(
            color: isSelected ? SettingsPalette.icon : SettingsPalette.stroke,
          ),
        ),
        child: Text(
          TimerProvider.formatDurationLabel(minutes),
          style: TextStyle(
            color: isSelected ? const Color(0xFF0B101A) : Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
