import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../providers/timer_provider.dart';

class TimerBottomSheets {
  const TimerBottomSheets._();

  static Future<int?> showCustomTimerDialer(
    BuildContext context, {
    required int initialMinutes,
  }) async {
    int tempMinutes = initialMinutes;
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF15100A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Color(0xFFC8A84A)),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(tempMinutes),
                        child: const Text(
                          'Set',
                          style: TextStyle(color: Color(0xFFF5D080)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Custom Timer',
                    style: TextStyle(
                      color: Color(0xFFF5D080),
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 180,
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hm,
                      initialTimerDuration: Duration(minutes: tempMinutes),
                      onTimerDurationChanged: (duration) {
                        final minutes = max(1, duration.inMinutes);
                        setSheetState(() {
                          tempMinutes = minutes;
                        });
                      },
                    ),
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
  }) {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF15100A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set Timer',
                style: TextStyle(
                  color: Color(0xFFF5D080),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: TimerProvider.presetsMinutes.map((m) {
                  final isSelected = m == selectedDurationMinutes;
                  return ChoiceChip(
                    label: Text('$m min'),
                    selected: isSelected,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF1C1208)
                          : const Color(0xFFF5D080),
                      fontWeight: FontWeight.w500,
                    ),
                    selectedColor: const Color(0xFFF5D080),
                    backgroundColor: const Color(0x332A1A0A),
                    side: const BorderSide(color: Color(0x66F5D080)),
                    onSelected: (_) => Navigator.of(context).pop(m),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(-1),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0x66F5D080)),
                    foregroundColor: const Color(0xFFF5D080),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.timer_outlined),
                  label: const Text('Custom time'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
