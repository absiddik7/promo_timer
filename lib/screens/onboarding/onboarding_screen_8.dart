import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/visual_settings_provider.dart';
import '../../widgets/candle_widget.dart';
import '../../styles/customization_presets.dart';
import '../../widgets/candle_painter_utils.dart';
import '../../widgets/onboarding_action_button.dart';

class OnboardingScreen8 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const OnboardingScreen8({super.key, required this.onNext, this.onBack});

  @override
  State<OnboardingScreen8> createState() => _OnboardingScreen8State();
}

class _OnboardingScreen8State extends State<OnboardingScreen8> {
  late Color _selectedCandleColor;
  late Color _selectedBgInnerColor;

  Color get _selectedBgOuterColor =>
      Color.lerp(_selectedBgInnerColor, Colors.black, 0.72) ??
      _selectedBgInnerColor;

  @override
  void initState() {
    super.initState();
    final visualSettings = context.read<VisualSettingsProvider>();
    final initialCandlePreset = _resolveInitialCandleColor(
      visualSettings.candleBodyColor,
    );
    final initialBackgroundPreset = _resolveInitialBackground(
      visualSettings.backgroundInnerColor,
    );
    _selectedCandleColor = initialCandlePreset.color;
    _selectedBgInnerColor = initialBackgroundPreset.innerColor;
  }

  CandleColorPreset _resolveInitialCandleColor(Color currentColor) {
    return CustomizationPresets.freeCandleColors.firstWhere(
      (preset) => preset.color.toARGB32() == currentColor.toARGB32(),
      orElse: () => CustomizationPresets.freeCandleColors.first,
    );
  }

  BackgroundColorPreset _resolveInitialBackground(Color currentColor) {
    return CustomizationPresets.freeBackgroundColors.firstWhere(
      (preset) => preset.innerColor.toARGB32() == currentColor.toARGB32(),
      orElse: () => CustomizationPresets.freeBackgroundColors.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visualSettings = context.read<VisualSettingsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF050302),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _OnboardingBackgroundPainter(
                inner: _selectedBgInnerColor,
                outer: _selectedBgOuterColor,
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 24),
              const Text(
                'Make it yours',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 130),
                      Center(
                        child: CandleWidget(
                          size: 250,
                          candleColor: _selectedCandleColor,
                          isAnimated: true,
                          flameScale: 0.82,
                          isFlameLive: false,
                        ),
                      ),
                      const Text(
                        'Candle Wax',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: CustomizationPresets.freeCandleColors.map((
                          preset,
                        ) {
                          final isSelected =
                              preset.color.toARGB32() ==
                              _selectedCandleColor.toARGB32();
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCandleColor = preset.color;
                              });
                              visualSettings.setCandleColor(preset.color);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: preset.color,
                                border: isSelected
                                    ? Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      )
                                    : Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 1,
                                      ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: preset.color.withValues(
                                            alpha: 0.5,
                                          ),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Background',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: CustomizationPresets.freeBackgroundColors
                            .map((preset) {
                              final presetOuter =
                                  Color.lerp(
                                    preset.innerColor,
                                    Colors.black,
                                    0.72,
                                  ) ??
                                  preset.innerColor;
                              final isSelected =
                                  preset.innerColor.toARGB32() ==
                                  _selectedBgInnerColor.toARGB32();
          
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedBgInnerColor = preset.innerColor;
                                  });
                                  visualSettings.setBackgroundColor(
                                    preset.innerColor,
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        preset.innerColor,
                                        presetOuter,
                                      ],
                                    ),
                                    border: isSelected
                                        ? Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          )
                                        : Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.3,
                                            ),
                                            width: 1,
                                          ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: presetOuter.withValues(
                                                alpha: 0.5,
                                              ),
                                              blurRadius: 12,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        )
                                      : null,
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: OnboardingActionButton(
                  label: 'Looks good',
                  onPressed: widget.onNext,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OnboardingBackgroundPainter extends CustomPainter {
  final Color inner;
  final Color outer;

  const _OnboardingBackgroundPainter({
    required this.inner,
    required this.outer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    drawBackground(canvas, size.width, size.height, inner, outer);
  }

  @override
  bool shouldRepaint(covariant _OnboardingBackgroundPainter oldDelegate) {
    return oldDelegate.inner != inner || oldDelegate.outer != outer;
  }
}
