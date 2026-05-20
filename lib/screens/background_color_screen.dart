import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/premium_provider.dart';
import '../providers/visual_settings_provider.dart';
import 'paywall_screen.dart';
import '../styles/settings_palette.dart';
import '../styles/customization_presets.dart';

class BackgroundColorScreen extends StatefulWidget {
  const BackgroundColorScreen({super.key});

  @override
  State<BackgroundColorScreen> createState() => _BackgroundColorScreenState();
}

class _BackgroundColorScreenState extends State<BackgroundColorScreen> {
  late final List<BackgroundColorPreset> _displayPresets;

  @override
  void initState() {
    super.initState();
    _displayPresets = _orderedPresets(
      context.read<VisualSettingsProvider>().backgroundInnerColor,
    );
  }

  List<BackgroundColorPreset> get _backgroundPresets =>
      CustomizationPresets.backgroundColors;

  List<BackgroundColorPreset> _orderedPresets(Color selectedColor) {
    final selectedColorValue = selectedColor.toARGB32();
    final selectedPresetIndex = _backgroundPresets.indexWhere(
      (preset) => preset.innerColor.toARGB32() == selectedColorValue,
    );
    if (selectedPresetIndex < 0) return _backgroundPresets;

    return [
      _backgroundPresets[selectedPresetIndex],
      ..._backgroundPresets.where((preset) {
        return preset.innerColor.toARGB32() != selectedColorValue;
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
    final premium = context.watch<PremiumProvider>();

    return Scaffold(
      backgroundColor: SettingsPalette.canvas,
      appBar: AppBar(
        backgroundColor: SettingsPalette.canvas,
        surfaceTintColor: SettingsPalette.canvas,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Background',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: _displayPresets.length,
          itemBuilder: (context, index) {
            final preset = _displayPresets[index];
            final isSelected =
                preset.innerColor.toARGB32() ==
                visualSettings.backgroundInnerColor.toARGB32();
            final previewOuter =
                Color.lerp(preset.innerColor, Colors.black, 0.72) ??
                preset.innerColor;

            return GestureDetector(
              onTap: () {
                if (preset.isPremium && !premium.isPremium) {
                  Navigator.of(context)
                      .push<bool>(
                        MaterialPageRoute(
                          builder: (_) => const PaywallScreen(
                            source: 'background colors',
                          ),
                        ),
                      )
                      .then((purchased) {
                        if (purchased == true && mounted) {
                          context.read<VisualSettingsProvider>().setBackgroundColor(
                                preset.innerColor,
                              );
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      });
                  return;
                }
                context.read<VisualSettingsProvider>().setBackgroundColor(
                  preset.innerColor,
                );
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: _buildAnimatedPresetCard(
                index: index,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFF5D080)
                              : Colors.white.withValues(alpha: 0.45),
                          width: isSelected ? 2.5 : 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFF5D080,
                                  ).withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: RadialGradient(
                                center: const Alignment(0, -0.2),
                                radius: 0.9,
                                colors: [preset.innerColor, previewOuter],
                              ),
                            ),
                          ),
                          if (preset.isPremium && !premium.isPremium)
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
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.2),
                                    Colors.black.withValues(alpha: 0.6),
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 11,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    preset.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
