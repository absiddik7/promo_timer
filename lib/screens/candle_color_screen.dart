import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/visual_settings_provider.dart';
import 'candle_screen.dart';
import '../styles/settings_palette.dart';

class _ColorPreset {
  final String label;
  final Color color;

  const _ColorPreset(this.label, this.color);
}

class CandleColorScreen extends StatefulWidget {
  const CandleColorScreen({super.key});

  @override
  State<CandleColorScreen> createState() => _CandleColorScreenState();
}

class _CandleColorScreenState extends State<CandleColorScreen> {
  static const List<_ColorPreset> _candlePresets = [
    _ColorPreset('Warm Wax', Color(0xFFD4C4A0)),
    _ColorPreset('Golden', Color(0xFFE0B35A)),
    _ColorPreset('Rose', Color(0xFFE3A29B)),
    _ColorPreset('Sea Glass', Color(0xFF9CC7C2)),
    _ColorPreset('Lavender', Color(0xFFC6B1E3)),
    _ColorPreset('Sunset', Color(0xFFF0A061)),
    _ColorPreset('Ivory Pearl', Color(0xFFF0E5CF)),
    _ColorPreset('Champagne', Color(0xFFE5C98C)),
    _ColorPreset('Amber Glow', Color(0xFFF2A34E)),
    _ColorPreset('Coral Blush', Color(0xFFEE9B8C)),
    _ColorPreset('Ruby Tint', Color(0xFFD17A7A)),
    _ColorPreset('Sage Cream', Color(0xFFBFD1B0)),
    _ColorPreset('Mint Frost', Color(0xFFC5E1D7)),
    _ColorPreset('Sky Powder', Color(0xFFB9CDE9)),
    _ColorPreset('Amethyst', Color(0xFFC9A8D8)),
    _ColorPreset('Obsidian Gold', Color(0xFF7F6A3A)),
    _ColorPreset('Platinum Wax', Color(0xFFD8D8D1)),
    _ColorPreset('Bronze Luxe', Color(0xFFB78A55)),
    _ColorPreset('Crimson Red', Color(0xFFC62828)),
    _ColorPreset('Royal Blue', Color(0xFF1E40AF)),
    _ColorPreset('Emerald Green', Color(0xFF0F8A5F)),
    _ColorPreset('Deep Violet', Color(0xFF6D28D9)),
    _ColorPreset('Carbon Black', Color(0xFF1F1F1F)),
  ];

  late final List<_ColorPreset> _displayPresets;

  @override
  void initState() {
    super.initState();
    _displayPresets = _orderedPresets(
      context.read<VisualSettingsProvider>().candleBodyColor,
    );
  }

  List<_ColorPreset> _orderedPresets(Color selectedColor) {
    final selectedColorValue = selectedColor.toARGB32();
    final selectedPresetIndex = _candlePresets.indexWhere(
      (preset) => preset.color.toARGB32() == selectedColorValue,
    );
    if (selectedPresetIndex < 0) return _candlePresets;

    return [
      _candlePresets[selectedPresetIndex],
      ..._candlePresets.where((preset) {
        return preset.color.toARGB32() != selectedColorValue;
      }),
    ];
  }

  Widget _buildAnimatedPresetCard({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 280 + (index % 4) * 35),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 14),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visualSettings = context.watch<VisualSettingsProvider>();

    return Scaffold(
      backgroundColor: SettingsPalette.canvas,
      appBar: AppBar(
        backgroundColor: SettingsPalette.canvas,
        surfaceTintColor: SettingsPalette.canvas,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Candle Color',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.76,
          ),
          itemCount: _displayPresets.length,
          itemBuilder: (context, index) {
            final preset = _displayPresets[index];
            final isSelected =
                preset.color.toARGB32() ==
                visualSettings.candleBodyColor.toARGB32();

            return GestureDetector(
              onTap: () {
                context.read<VisualSettingsProvider>().setCandleColor(
                  preset.color,
                );
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: _buildAnimatedPresetCard(
                index: index,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        SettingsPalette.panelStart,
                        SettingsPalette.panelEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFF5D080)
                          : SettingsPalette.stroke,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 38),
                        child: CandleStaticPreview(waxColor: preset.color),
                      ),
                      if (isSelected)
                        const Positioned(
                          top: 10,
                          right: 10,
                          child: Icon(
                            Icons.check_circle,
                            color: Color(0xFFF5D080),
                            size: 24,
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(11),
                              bottomRight: Radius.circular(11),
                            ),
                          ),
                          child: Text(
                            preset.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
