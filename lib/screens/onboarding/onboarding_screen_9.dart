import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../providers/sound_settings_provider.dart';
import '../../widgets/onboarding_action_button.dart';

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
  SoundSettingsProvider? _soundSettings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _soundSettings ??= context.read<SoundSettingsProvider>();
  }

  Future<void> _playPreview(int index) async {
    await _soundSettings?.toggleTrackPreview(index);
  }

  @override
  void deactivate() {
    // Ensure preview stops when the page loses focus (PageView navigation).
    _soundSettings?.stopPreviewPlayback();
    super.deactivate();
  }

  @override
  void dispose() {
    // Use cached provider reference to avoid looking up an ancestor during dispose().
    _soundSettings?.stopPreviewPlayback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1320),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Explore the sound library.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preview tracks here. You can choose your timer sound in Settings.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ...context.watch<SoundSettingsProvider>().availableTracks.asMap().entries.map((entry) {
                    final index = entry.key;
                    final track = entry.value;
                    final isTrackPlaying =
                        context.watch<SoundSettingsProvider>().isTrackPlaying(index);
      
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SoundOptionCard(
                        label: track.label,
                        imageAssetPath: track.imageAssetPath,
                        isPlaying: isTrackPlaying,
                        onPreviewTap: () => _playPreview(index),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: OnboardingActionButton(
              label: 'Perfect',
              onPressed: widget.onNext,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundOptionCard extends StatelessWidget {
  final String label;
  final String imageAssetPath;
  final bool isPlaying;
  final VoidCallback onPreviewTap;

  const _SoundOptionCard({
    required this.label,
    required this.imageAssetPath,
    required this.isPlaying,
    required this.onPreviewTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        color: Colors.white.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: SvgPicture.asset(
                    imageAssetPath,
                    fit: BoxFit.contain,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFF5D080),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onPreviewTap,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0x44F5D080)),
              foregroundColor: const Color(0xFFF5D080),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 18,
            ),
            label: Text(isPlaying ? 'Pause' : 'Play'),
          ),
        ],
      ),
    );
  }
}
