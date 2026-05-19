import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/onboarding_action_button.dart';

class OnboardingScreen5 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const OnboardingScreen5({
    super.key,
    required this.onNext,
    this.onBack,
  });

  @override
  State<OnboardingScreen5> createState() => _OnboardingScreen5State();
}

class _OnboardingScreen5State extends State<OnboardingScreen5> {
  late int? _selected;
  final List<Map<String, dynamic>> _options = [
    {'label': '15 minutes', 'minutes': 15, 'icon': Icons.schedule_rounded},
    {'label': '25 minutes', 'minutes': 25, 'icon': Icons.schedule_rounded},
    {'label': '45 minutes', 'minutes': 45, 'icon': Icons.schedule_rounded},
    {'label': '60 minutes', 'minutes': 60, 'icon': Icons.schedule_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _selected = context.read<OnboardingProvider>().sessionDuration;
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
                    'How long can you focus at a stretch?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
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
                        final minutes = option['minutes'] as int;
                        final icon = option['icon'] as IconData;
                        final isSelected = _selected == minutes;
      
                        return _SurveyOptionCard(
                          label: label,
                          icon: icon,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              _selected = minutes;
                            });
                            context.read<OnboardingProvider>().setSessionDuration(minutes);
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

class _SurveyOptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SurveyOptionCard({
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
        padding: const EdgeInsets.all(20),
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
