import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/visual_settings_provider.dart';

class _ColorPreset {
  final String label;
  final Color color;

  const _ColorPreset(this.label, this.color);
}

class BackgroundColorScreen extends StatefulWidget {
  const BackgroundColorScreen({super.key});

  @override
  State<BackgroundColorScreen> createState() => _BackgroundColorScreenState();
}

class _BackgroundColorScreenState extends State<BackgroundColorScreen> {
  static const List<_ColorPreset> _backgroundPresets = [
    _ColorPreset('Ember', Color(0xFF2A1A0A)),
    _ColorPreset('Night', Color(0xFF10131A)),
    _ColorPreset('Forest', Color(0xFF102018)),
    _ColorPreset('Plum', Color(0xFF20111F)),
    _ColorPreset('Ink', Color(0xFF0A0604)),
    _ColorPreset('Slate', Color(0xFF17212B)),
    _ColorPreset('Ocean Deep', Color(0xFF0B1E33)),
    _ColorPreset('Emerald Room', Color(0xFF0F2A22)),
    _ColorPreset('Burgundy', Color(0xFF2D1116)),
    _ColorPreset('Midnight Teal', Color(0xFF10272B)),
    _ColorPreset('Royal Navy', Color(0xFF111D3B)),
    _ColorPreset('Chocolate', Color(0xFF2B1A13)),
    _ColorPreset('Velvet Black', Color(0xFF080808)),
    _ColorPreset('Champagne Noir', Color(0xFF1B1610)),
    _ColorPreset('Sapphire Luxe', Color(0xFF101A39)),
    _ColorPreset('Jade Noir', Color(0xFF12211A)),
  ];

  @override
  Widget build(BuildContext context) {
    final visualSettings = context.watch<VisualSettingsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        surfaceTintColor: const Color(0xFF0F0F0F),
        elevation: 0,
        title: const Text(
          'Background',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            fontSize: 24,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: _backgroundPresets.length,
          itemBuilder: (context, index) {
            final preset = _backgroundPresets[index];
            final isSelected =
                preset.color.toARGB32() ==
                visualSettings.backgroundInnerColor.toARGB32();
            final outerColor =
                Color.lerp(preset.color, Colors.black, 0.72) ?? preset.color;

            return GestureDetector(
              onTap: () {
                context.read<VisualSettingsProvider>().setBackgroundColor(
                  preset.color,
                );
              },
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFF5D080)
                            : Colors.white12,
                        width: isSelected ? 2.5 : 1,
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
                              colors: [preset.color, outerColor],
                            ),
                          ),
                        ),
                        // Content overlay
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
                  // Selection indicator
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: AnimatedScale(
                        scale: isSelected ? 1.0 : 0.8,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF5D080),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF1C1208),
                            size: 20,
                            weight: 600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
