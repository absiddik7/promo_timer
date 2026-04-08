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

  void _showColorPreview(
    BuildContext context,
    _ColorPreset preset,
    Color currentColor,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return _ColorPreviewDialog(
          preset: preset,
          currentColor: currentColor,
          onConfirm: () {
            context.read<VisualSettingsProvider>().setBackgroundColor(preset.color);
            Navigator.of(context).pop();
          },
        );
      },
    );
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
          'Background Color',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
            letterSpacing: 1,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: _backgroundPresets.length,
          itemBuilder: (context, index) {
            final preset = _backgroundPresets[index];
            final isSelected =
                preset.color.toARGB32() ==
                visualSettings.backgroundInnerColor.toARGB32();

            return GestureDetector(
              onTap: () => _showColorPreview(
                context,
                preset,
                visualSettings.backgroundInnerColor,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFF5D080)
                        : Colors.white10,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: preset.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    if (isSelected)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFF5D080),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black54,
                                border: Border.all(
                                  color: const Color(0xFFF5D080),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Color(0xFFF5D080),
                                size: 28,
                              ),
                            ),
                          ),
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
                            fontSize: 12,
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
            );
          },
        ),
      ),
    );
  }
}

class _ColorPreviewDialog extends StatelessWidget {
  final _ColorPreset preset;
  final Color currentColor;
  final VoidCallback onConfirm;

  const _ColorPreviewDialog({
    required this.preset,
    required this.currentColor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF15100A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              preset.label,
              style: const TextStyle(
                color: Color(0xFFF5D080),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: preset.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFF5D080),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: preset.color.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5D080),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Set Color',
                    style: TextStyle(
                      color: Color(0xFF1C1208),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
