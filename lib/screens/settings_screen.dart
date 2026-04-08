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

    final soundSubtitle =
        '${soundSettings.availableTracks.length} sound option${soundSettings.availableTracks.length == 1 ? '' : 's'} • ${soundSettings.selectedTrackLabel}';

    return Scaffold(
      backgroundColor: _SettingsPalette.canvas,
      appBar: AppBar(
        backgroundColor: _SettingsPalette.canvas,
        surfaceTintColor: _SettingsPalette.canvas,
        elevation: 0,
        title: const Text(
          'Menu',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 28,
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0, end: 1),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 20),
              child: child,
            ),
          );
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 14, 18, 12),
                child: _SectionLabel('Appearance'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverList.list(
                children: [
                  _ActionSettingTile(
                    title: 'Background color',
                    subtitle: 'Change the scene backdrop',
                    icon: Icons.wallpaper_rounded,
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
                  _ActionSettingTile(
                    title: 'Candle color',
                    subtitle: 'Change the candle wax tone',
                    icon: Icons.local_fire_department_rounded,
                    preview: _ColorPreview(
                      colors: [visualSettings.candleBodyColor],
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CandleColorScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: _SectionLabel('Session'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverList.list(
                children: [
                  _ActionSettingTile(
                    title: 'Sound',
                    subtitle: soundSubtitle,
                    icon: Icons.graphic_eq_rounded,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SoundSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const _ActionSettingTile(
                    title: 'Timer',
                    subtitle: 'Default duration and timer behavior',
                    icon: Icons.timer_rounded,
                    badgeLabel: 'Soon',
                  ),
                  const SizedBox(height: 12),
                  _ToggleSettingTile(
                    title: 'Haptic feedback',
                    subtitle: 'Vibrate when timer ends',
                    icon: Icons.vibration_rounded,
                    value: visualSettings.hapticOnTimerEnd,
                    onChanged: _setHapticOnTimerEnd,
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: _SectionLabel('Device'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverList.list(
                children: const [
                  _ActionSettingTile(
                    title: 'Display',
                    subtitle: 'Keep screen on and visual options',
                    icon: Icons.desk_rounded,
                    badgeLabel: 'Soon',
                  ),
                  SizedBox(height: 12),
                  _ActionSettingTile(
                    title: 'About',
                    subtitle: 'App version and details',
                    icon: Icons.info_outline_rounded,
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsPalette {
  static const canvas = Color(0xFF080B11);
  static const panelStart = Color(0xFF111827);
  static const panelEnd = Color(0xFF0A0E16);
  static const stroke = Color(0x33A6B4CF);
  static const icon = Color(0xFFF0CB7A);
  static const textMuted = Color(0xFF9EA9BE);
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _SettingsPalette.textMuted,
        fontSize: 12,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ActionSettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? preview;
  final String? badgeLabel;
  final VoidCallback? onTap;

  const _ActionSettingTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.preview,
    this.badgeLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: _SettingsPalette.stroke),
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_SettingsPalette.panelStart, _SettingsPalette.panelEnd],
        ),
      ),
      child: Row(
        children: [
          preview ??
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Icon(icon, color: _SettingsPalette.icon),
              ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _SettingsPalette.textMuted,
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (badgeLabel != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                badgeLabel!,
                style: const TextStyle(
                  color: _SettingsPalette.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Colors.white10,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white70,
              size: 20,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
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
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: colors.length > 1
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              )
            : null,
        color: colors.isNotEmpty ? colors[0] : Colors.grey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
    );
  }
}

class _ToggleSettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleSettingTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: _SettingsPalette.stroke),
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_SettingsPalette.panelStart, _SettingsPalette.panelEnd],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Icon(icon, color: _SettingsPalette.icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _SettingsPalette.textMuted,
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.95,
            child: Switch.adaptive(
              value: value,
              activeColor: const Color(0xFF0F1320),
              activeTrackColor: _SettingsPalette.icon,
              inactiveTrackColor: Colors.white24,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
