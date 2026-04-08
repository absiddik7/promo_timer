import 'package:flutter/material.dart';
import 'package:promo_timer/providers/sound_settings_provider.dart';
import 'package:promo_timer/screens/sound_settings_screen.dart';
import 'package:promo_timer/screens/background_color_screen.dart';
import 'package:promo_timer/screens/candle_color_screen.dart';
import 'package:provider/provider.dart';
import '../providers/visual_settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _setHapticOnTimerEnd(bool enabled) {
    context.read<VisualSettingsProvider>().setHapticOnTimerEnd(enabled);
  }

  @override
  Widget build(BuildContext context) {
    final visualSettings = context.watch<VisualSettingsProvider>();
    final soundSettings = context.watch<SoundSettingsProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Menu',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MenuCard(
            title: 'Background color',
            subtitle: 'Change the scene backdrop',
            icon: Icons.wallpaper_outlined,
            preview: _ColorPreview(
              colors: [
                visualSettings.backgroundInnerColor,
                visualSettings.backgroundOuterColor,
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BackgroundColorScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _MenuCard(
            title: 'Candle color',
            subtitle: 'Change the candle wax tone',
            icon: Icons.local_fire_department_outlined,
            preview: _ColorPreview(colors: [visualSettings.candleBodyColor]),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CandleColorScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _MenuCard(
            title: 'Sound',
            subtitle:
                '${soundSettings.availableTracks.length} sound option${soundSettings.availableTracks.length == 1 ? '' : 's'} • ${soundSettings.selectedTrackLabel}',
            icon: Icons.volume_up_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SoundSettingsScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          const _MenuCard(
            title: 'Timer',
            subtitle: 'Default duration and timer behavior',
            icon: Icons.timer_outlined,
          ),
          const SizedBox(height: 12),
          _ToggleMenuCard(
            title: 'Haptic feedback',
            subtitle: 'Vibrate when timer ends',
            icon: Icons.vibration_outlined,
            value: visualSettings.hapticOnTimerEnd,
            onChanged: _setHapticOnTimerEnd,
          ),
          const SizedBox(height: 12),
          const _MenuCard(
            title: 'Display',
            subtitle: 'Keep screen on and visual options',
            icon: Icons.display_settings_outlined,
          ),
          const SizedBox(height: 12),
          const _MenuCard(
            title: 'About',
            subtitle: 'App version and details',
            icon: Icons.info_outline,
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? preview;
  final VoidCallback? onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.preview,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          preview ?? Icon(icon, color: const Color(0xFFF5D080)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: card,
    );
  }
}

class _ColorPreview extends StatelessWidget {
  final List<Color> colors;

  const _ColorPreview({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
    );
  }
}

class _ToggleMenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleMenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF5D080)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
