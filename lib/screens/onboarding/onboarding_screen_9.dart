import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/sound_settings_provider.dart';

class OnboardingScreen9 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const OnboardingScreen9({
    super.key,
    required this.onNext,
    this.onBack,
  });

  @override
  State<OnboardingScreen9> createState() => _OnboardingScreen9State();
}

class _OnboardingScreen9State extends State<OnboardingScreen9> {
  late String? _selected;
  double _volume = 0.5;

  final List<Map<String, dynamic>> _soundOptions = [
    {'label': 'Silence', 'icon': Icons.volume_mute_rounded},
    {'label': 'Lo-fi music', 'icon': Icons.music_note_rounded},
    {'label': 'Rain sounds', 'icon': Icons.cloud_rounded},
    {'label': 'White noise', 'icon': Icons.hearing_rounded},
    {'label': 'Crackling fire', 'icon': Icons.local_fire_department_rounded},
  ];

  @override
  void initState() {
    super.initState();
    final onboarding = context.read<OnboardingProvider>();
    final soundSettings = context.read<SoundSettingsProvider>();
    
    // Auto-select sound from screen 6, or fall back to silence
    _selected = onboarding.soundPreference ?? soundSettings.selectedTrackLabel;
  }

  void _playPreview(String sound) {
    // TODO: Implement sound preview with sound_settings_provider
    print('Playing preview for: $sound at volume: $_volume');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1320),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Set the mood.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Sound options
                    ...List.generate(_soundOptions.length, (index) {
                      final option = _soundOptions[index];
                      final label = option['label'] as String;
                      final icon = option['icon'] as IconData;
                      final isSelected = _selected == label;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SoundOptionCard(
                          label: label,
                          icon: icon,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              _selected = label;
                            });
                          },
                          onPreviewTap: () => _playPreview(label),
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
                    // Volume slider
                    const Text(
                      'Volume',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.volume_down_rounded,
                          color: Colors.white.withOpacity(0.5),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white.withOpacity(0.2),
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              value: _volume,
                              onChanged: (value) {
                                setState(() {
                                  _volume = value;
                                });
                              },
                              divisions: 10,
                              label: '${(_volume * 100).toStringAsFixed(0)}%',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F1320),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Perfect',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundOptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onPreviewTap;

  const _SoundOptionCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.onPreviewTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? Colors.white.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.1),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF0F1320)
                    : Colors.white.withOpacity(0.7),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (label != 'Silence')
              GestureDetector(
                onTap: onPreviewTap,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            if (isSelected && label != 'Silence') const SizedBox(width: 12),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
