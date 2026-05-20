import 'package:flutter/material.dart';
import '../../services/timer_notification_service.dart';
import '../../widgets/onboarding_action_button.dart';

class OnboardingScreen11 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback? onBack;

  const OnboardingScreen11({
    super.key,
    required this.onNext,
    required this.onSkip,
    this.onBack,
  });

  @override
  State<OnboardingScreen11> createState() => _OnboardingScreen11State();
}

class _OnboardingScreen11State extends State<OnboardingScreen11> {
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
    // Automatically request permission when landing on this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoRequestPermission();
    });
  }

  Future<void> _autoRequestPermission() async {
    final isGranted = await TimerNotificationService.instance
        .isPermissionGranted();
    if (!isGranted && mounted) {
      _requestNotificationPermission();
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (_isRequestingPermission) return;

    setState(() {
      _isRequestingPermission = true;
    });

    await TimerNotificationService.instance.requestPermissions();

    if (!mounted) return;

    setState(() {
      _isRequestingPermission = false;
    });

    // Auto-advance after permission request completes
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        widget.onNext();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1320),
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFFD4C4A0),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 40),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Get a gentle nudge when your session ends.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Turn on notifications so we can give you a calm reminder to pause, breathe, and enjoy your break.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFB8A89F).withOpacity(0.95),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withOpacity(0.06),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: const Color(0xFFD4C4A0).withOpacity(0.16),
                        ),
                        child: const Icon(
                          Icons.notifications_rounded,
                          color: Color(0xFFD4C4A0),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'A soft reminder can help you close each focus block with intention.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.82),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OnboardingActionButton(
                    label: _isRequestingPermission
                        ? 'Requesting permission...'
                        : 'Enable notifications',
                    onPressed: _isRequestingPermission
                        ? null
                        : _requestNotificationPermission,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OnboardingActionButton.outlined(
                    label: 'Not now',
                    onPressed: widget.onSkip,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
