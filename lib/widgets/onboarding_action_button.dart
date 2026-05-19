import 'package:flutter/material.dart';

class OnboardingActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? disabledBackgroundColor;
  final BorderSide? borderSide;

  const OnboardingActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = const Color(0xFFD9B14D),
    this.foregroundColor = const Color(0xFF0F1320),
    this.disabledBackgroundColor = const Color(0x66D9B14D),
  }) : outlined = false,
       borderSide = null;

  const OnboardingActionButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.foregroundColor = Colors.white,
    this.borderSide,
  }) : outlined = true,
       backgroundColor = Colors.transparent,
       disabledBackgroundColor = null;

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: foregroundColor,
            side:
                borderSide ??
                BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: disabledBackgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
