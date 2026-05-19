import 'package:flutter/material.dart';

class OnboardingProgressBar extends StatelessWidget {
  final int currentScreen; // 1-based index for visible onboarding screens
  final int totalScreens; // total number of onboarding screens to show in progress
  final VoidCallback? onBackPressed;
  final Duration animationDuration;

  const OnboardingProgressBar({
    super.key,
    required this.currentScreen,
    this.totalScreens = 12,
    this.onBackPressed,
    this.animationDuration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentScreen / totalScreens;
    final canGoBack = currentScreen > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: canGoBack ? onBackPressed : null,
            child: Opacity(
              opacity: canGoBack ? 1.0 : 0.3,
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$currentScreen/$totalScreens',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
