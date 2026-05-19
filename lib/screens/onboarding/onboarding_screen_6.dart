import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/onboarding_action_button.dart';

class OnboardingScreen6 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const OnboardingScreen6({super.key, required this.onNext, this.onBack});

  @override
  State<OnboardingScreen6> createState() => _OnboardingScreen6State();
}

class _OnboardingScreen6State extends State<OnboardingScreen6> {
  late String? _selected;
  final List<Map<String, dynamic>> _options = [
    {'label': 'Silence', 'icon': Icons.volume_mute_rounded},
    {'label': 'Lo-fi music', 'icon': Icons.music_note_rounded},
    {'label': 'Rain / Nature sounds', 'icon': Icons.cloud_rounded},
    {'label': 'White noise', 'icon': Icons.hearing_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _selected = context.read<OnboardingProvider>().soundPreference;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1320),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What helps you focus?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _options.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final option = _options[index];
                        final label = option['label'] as String;
                        final icon = option['icon'] as IconData;
                        final isSelected = _selected == label;
      
                        return _SoundOptionCard(
                          label: label,
                          icon: icon,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              _selected = label;
                            });
                            context
                                .read<OnboardingProvider>()
                                .setSoundPreference(label);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: OnboardingActionButton(
              label: 'Next',
              onPressed: _selected != null ? widget.onNext : null,
              disabledBackgroundColor: Colors.white.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundOptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SoundOptionCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
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
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
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

            // Play button
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }
}
