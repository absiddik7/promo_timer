import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/visual_settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const List<_ColorPreset> _backgroundPresets = [
    _ColorPreset('Ember', Color(0xFF2A1A0A)),
    _ColorPreset('Night', Color(0xFF10131A)),
    _ColorPreset('Forest', Color(0xFF102018)),
    _ColorPreset('Plum', Color(0xFF20111F)),
    _ColorPreset('Ink', Color(0xFF0A0604)),
    _ColorPreset('Slate', Color(0xFF17212B)),
  ];

  static const List<_ColorPreset> _candlePresets = [
    _ColorPreset('Warm Wax', Color(0xFFD4C4A0)),
    _ColorPreset('Golden', Color(0xFFE0B35A)),
    _ColorPreset('Rose', Color(0xFFE3A29B)),
    _ColorPreset('Sea Glass', Color(0xFF9CC7C2)),
    _ColorPreset('Lavender', Color(0xFFC6B1E3)),
    _ColorPreset('Sunset', Color(0xFFF0A061)),
  ];

  Future<void> _pickColor({
    required String title,
    required String subtitle,
    required List<_ColorPreset> presets,
    required Color currentColor,
    required void Function(Color) onSelected,
  }) async {
    final selected = await showModalBottomSheet<Color>(
      context: context,
      backgroundColor: const Color(0xFF15100A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFF5D080),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: presets.map((preset) {
                  final isSelected =
                      preset.color.toARGB32() == currentColor.toARGB32();
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(preset.color),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: preset.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFF5D080)
                                  : Colors.white24,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Color(0xFF1C1208),
                                  size: 22,
                                )
                              : null,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          preset.label,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(currentColor),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0x66F5D080)),
                    foregroundColor: const Color(0xFFF5D080),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Keep current color'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) return;
    onSelected(selected);
    setState(() {});
  }

  void _setBackgroundColor(Color color) {
    context.read<VisualSettingsProvider>().setBackgroundColor(color);
  }

  void _setCandleColor(Color color) {
    context.read<VisualSettingsProvider>().setCandleColor(color);
  }

  @override
  Widget build(BuildContext context) {
    final visualSettings = context.watch<VisualSettingsProvider>();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
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
              _pickColor(
                title: 'Background color',
                subtitle: 'Pick the backdrop for the candle scene.',
                presets: _backgroundPresets,
                currentColor: visualSettings.backgroundInnerColor,
                onSelected: _setBackgroundColor,
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
              _pickColor(
                title: 'Candle color',
                subtitle: 'Pick the wax tone for the animated candle.',
                presets: _candlePresets,
                currentColor: visualSettings.candleBodyColor,
                onSelected: _setCandleColor,
              );
            },
          ),
          const SizedBox(height: 12),
          const _MenuCard(
            title: 'Audio',
            subtitle: 'Sound effects and volume',
            icon: Icons.volume_up_outlined,
          ),
          const SizedBox(height: 12),
          const _MenuCard(
            title: 'Timer',
            subtitle: 'Default duration and timer behavior',
            icon: Icons.timer_outlined,
          ),
          const SizedBox(height: 12),
          const _MenuCard(
            title: 'Haptics',
            subtitle: 'Feedback on interactions and completion',
            icon: Icons.vibration_outlined,
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

class _ColorPreset {
  final String label;
  final Color color;

  const _ColorPreset(this.label, this.color);
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
