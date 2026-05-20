import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../providers/premium_provider.dart';
import '../providers/sound_settings_provider.dart';
import '../styles/settings_palette.dart';
import 'paywall_screen.dart';

class SoundSettingsScreen extends StatefulWidget {
  const SoundSettingsScreen({super.key});

  @override
  State<SoundSettingsScreen> createState() => _SoundSettingsScreenState();
}

class _SoundSettingsScreenState extends State<SoundSettingsScreen>
    with WidgetsBindingObserver {
  late SoundSettingsProvider _soundSettingsProvider;

  void _stopPreviewPlayback() {
    unawaited(_soundSettingsProvider.stopPreviewPlayback());
  }

  @override
  void initState() {
    super.initState();
    _soundSettingsProvider = context.read<SoundSettingsProvider>();
    WidgetsBinding.instance.addObserver(this);
    _soundSettingsProvider.load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopPreviewPlayback();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPreviewPlayback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioSettings = context.watch<SoundSettingsProvider>();
    final premium = context.watch<PremiumProvider>();

    return Scaffold(
      backgroundColor: SettingsPalette.canvas,
      appBar: AppBar(
        backgroundColor: SettingsPalette.canvas,
        surfaceTintColor: SettingsPalette.canvas,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Sound',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: SettingsPalette.stroke),
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [SettingsPalette.panelStart, SettingsPalette.panelEnd],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.volume_up_outlined,
                      color: Color(0xFFF5D080),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Timer sound',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    Switch.adaptive(
                      value: audioSettings.isEnabled,
                      activeColor: SettingsPalette.icon,
                      onChanged: (value) => context
                          .read<SoundSettingsProvider>()
                          .setEnabled(value),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Volume ${(audioSettings.volume * 100).round()}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Slider(
                  value: audioSettings.volume,
                  onChanged: audioSettings.isEnabled
                      ? (value) => context
                            .read<SoundSettingsProvider>()
                            .setVolume(value)
                      : null,
                  activeColor: const Color(0xFFF5D080),
                  inactiveColor: Colors.white24,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sound options',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          ...audioSettings.availableTracks.asMap().entries.map((entry) {
            final index = entry.key;
            final track = entry.value;
            final isSelected = index == audioSettings.selectedTrackIndex;
            final isTrackPlaying = audioSettings.isTrackPlaying(index);
            final isPremium = track.isPremium;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFF5D080)
                        : SettingsPalette.stroke,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
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
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0x1FFFFFFF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: SvgPicture.asset(
                        track.imageAssetPath,
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
                        track.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: audioSettings.isEnabled
                              ? () => context
                                    .read<SoundSettingsProvider>()
                                    .toggleTrackPreview(index)
                              : null,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0x44F5D080)),
                            foregroundColor: const Color(0xFFF5D080),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: Icon(
                            isTrackPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 18,
                          ),
                          label: Text(isTrackPlaying ? 'Pause' : 'Play'),
                        ),
                        const SizedBox(width: 8),
                        if (isPremium && !premium.isPremium)
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context)
                                  .push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => const PaywallScreen(
                                        source: 'sound options',
                                      ),
                                    ),
                                  )
                                  .then((purchased) {
                                    if (purchased == true && mounted) {
                                      context
                                          .read<SoundSettingsProvider>()
                                          .setSelectedTrackIndex(
                                            index,
                                            allowPremium: true,
                                          );
                                    }
                                  });
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: Color(0x44373737),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_rounded,
                                color: Color(0xFFF5D080),
                                size: 18,
                              ),
                            ),
                          )
                        else if (isSelected)
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2D6A4F),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          )
                        else
                          ElevatedButton(
                            onPressed: () => context
                                .read<SoundSettingsProvider>()
                                .setSelectedTrackIndex(
                                  index,
                                  allowPremium: premium.isPremium,
                                ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF5D080),
                              foregroundColor: const Color(0xFF1C1208),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(isSelected ? 'Selected' : 'Select'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
