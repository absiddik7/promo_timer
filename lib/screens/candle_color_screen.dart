import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/visual_settings_provider.dart';
import 'candle_screen.dart';
import '../styles/settings_palette.dart';
import '../styles/customization_presets.dart';

class CandleColorScreen extends StatefulWidget {
  const CandleColorScreen({super.key});

  @override
  State<CandleColorScreen> createState() => _CandleColorScreenState();
}

class _CandleColorScreenState extends State<CandleColorScreen> {
  late final List<CandleColorPreset> _displayPresets;

  @override
  void initState() {
    super.initState();
    _displayPresets = _orderedPresets(
      context.read<VisualSettingsProvider>().candleBodyColor,
    );
  }

  List<CandleColorPreset> get _candlePresets => CustomizationPresets.candleColors;

  List<CandleColorPreset> _orderedPresets(Color selectedColor) {
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
                if (preset.isPremium) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('This candle color is premium locked.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  return;
                }
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
                      if (preset.isPremium)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFF5D080).withValues(alpha: 0.8),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              color: Color(0xFFF5D080),
                              size: 14,
                            ),
                          ),
                        ),
                      if (isSelected)
                        const Positioned(
                          top: 10,
                          left: 10,
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
