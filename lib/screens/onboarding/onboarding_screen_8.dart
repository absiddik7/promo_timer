import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/visual_settings_provider.dart';

class OnboardingScreen8 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const OnboardingScreen8({
    super.key,
    required this.onNext,
    this.onBack,
  });

  @override
  State<OnboardingScreen8> createState() => _OnboardingScreen8State();
}

class _OnboardingScreen8State extends State<OnboardingScreen8> {
  late Color _selectedCandleColor;
  late Color _selectedBgInnerColor;
  late Color _selectedBgOuterColor;

  static const List<Color> _candleColors = [
    Color(0xFFD4C4A0), // Cream
    Color(0xFFE8514D), // Red
    Color(0xFF6B9BD1), // Blue
    Color(0xFF7EC77F), // Green
    Color(0xFFC6A8E3), // Purple
    Color(0xFF2A2A2A), // Black
  ];

  static const List<(String, Color, Color)> _bgColors = [
    ('Dark Navy', Color(0xFF0A1428), Color(0xFF1B2D4A)),
    ('Warm Black', Color(0xFF0F0A08), Color(0xFF1A1410)),
    ('Soft White', Color(0xFFF5F0EB), Color(0xFFE8DFD5)),
    ('Forest Green', Color(0xFF1A3B2E), Color(0xFF2D5A47)),
    ('Dusty Rose', Color(0xFF3D2A2E), Color(0xFF5A3D42)),
    ('Deep Purple', Color(0xFF2B1A3B), Color(0xFF4A2E5F)),
  ];

  @override
  void initState() {
    super.initState();
    final visualSettings = context.read<VisualSettingsProvider>();
    _selectedCandleColor = visualSettings.candleBodyColor;
    _selectedBgInnerColor = visualSettings.backgroundInnerColor;
    _selectedBgOuterColor = visualSettings.backgroundOuterColor;
  }

  @override
  Widget build(BuildContext context) {
    final visualSettings = context.read<VisualSettingsProvider>();

    return Scaffold(
      backgroundColor: _selectedBgOuterColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Make it yours.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Live candle preview
                    Center(
                      child: SizedBox(
                        width: 120,
                        height: 160,
                        child: CustomPaint(
                          painter: _CandlePreviewPainter(
                            candleColor: _selectedCandleColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Candle color selection
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
                      children: _candleColors.map((color) {
                        final isSelected = color.value == _selectedCandleColor.value;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCandleColor = color;
                            });
                            visualSettings.setCandleColor(color);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 2)
                                  : Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.5),
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
                    const SizedBox(height: 40),
                    // Background color selection
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
                      children: _bgColors.map((bgOption) {
                        final (label, inner, outer) = bgOption;
                        final isSelected =
                            inner.value == _selectedBgInnerColor.value &&
                            outer.value == _selectedBgOuterColor.value;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedBgInnerColor = inner;
                              _selectedBgOuterColor = outer;
                            });
                            visualSettings.setBackgroundColor(inner);
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
                                colors: [inner, outer],
                              ),
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 2)
                                  : Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: outer.withOpacity(0.5),
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
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F1320),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Looks good',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandlePreviewPainter extends CustomPainter {
  final Color candleColor;

  _CandlePreviewPainter({required this.candleColor});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Candle body
    final bodyRect = Rect.fromLTWH(
      width * 0.25,
      height * 0.3,
      width * 0.5,
      height * 0.5,
    );

    final bodyPaint = Paint()
      ..color = candleColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(width * 0.08)),
      bodyPaint,
    );

    // Wax pool
    final poolPaint = Paint()
      ..color = candleColor.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(width / 2, height * 0.8),
        width: width * 0.6,
        height: height * 0.2,
      ),
      poolPaint,
    );

    // Flame
    final flamePaint = Paint()
      ..color = const Color(0xFFFFA500)
      ..style = PaintingStyle.fill;

    final flameX = width / 2;
    final flameY = height * 0.3 - (height * 0.15);

    final flamePath = Path();
    flamePath.moveTo(flameX, flameY - (height * 0.12));
    flamePath.quadraticBezierTo(
      flameX - (width * 0.05),
      flameY - (height * 0.06),
      flameX - (width * 0.03),
      flameY,
    );
    flamePath.quadraticBezierTo(
      flameX - (width * 0.01),
      flameY + (height * 0.04),
      flameX,
      flameY + (height * 0.02),
    );
    flamePath.quadraticBezierTo(
      flameX + (width * 0.01),
      flameY + (height * 0.04),
      flameX + (width * 0.03),
      flameY,
    );
    flamePath.quadraticBezierTo(
      flameX + (width * 0.05),
      flameY - (height * 0.06),
      flameX,
      flameY - (height * 0.12),
    );
    flamePath.close();

    canvas.drawPath(flamePath, flamePaint);
  }

  @override
  bool shouldRepaint(_CandlePreviewPainter oldDelegate) {
    return oldDelegate.candleColor.value != candleColor.value;
  }
}
