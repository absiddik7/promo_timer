import 'package:flutter/material.dart';

class CandleColorPreset {
  final String label;
  final Color color;
  final bool isPremium;

  const CandleColorPreset({
    required this.label,
    required this.color,
    required this.isPremium,
  });
}

class BackgroundColorPreset {
  final String label;
  final Color innerColor;
  final Color outerColor;
  final bool isPremium;

  const BackgroundColorPreset({
    required this.label,
    required this.innerColor,
    required this.outerColor,
    required this.isPremium,
  });
}

class CustomizationPresets {
  static const List<CandleColorPreset> candleColors = [
    CandleColorPreset(label: 'Warm Wax', color: Color(0xFFD4C4A0), isPremium: false),
    CandleColorPreset(label: 'Golden', color: Color(0xFFE0B35A), isPremium: false),
    CandleColorPreset(label: 'Rose', color: Color(0xFFE3A29B), isPremium: false),
    CandleColorPreset(label: 'Sea Glass', color: Color(0xFF9CC7C2), isPremium: false),
    CandleColorPreset(label: 'Lavender', color: Color(0xFFC6B1E3), isPremium: false),
    CandleColorPreset(label: 'Sunset', color: Color(0xFFF0A061), isPremium: false),
    CandleColorPreset(label: 'Ivory Pearl', color: Color(0xFFF0E5CF), isPremium: true),
    CandleColorPreset(label: 'Champagne', color: Color(0xFFE5C98C), isPremium: true),
    CandleColorPreset(label: 'Amber Glow', color: Color(0xFFF2A34E), isPremium: true),
    CandleColorPreset(label: 'Coral Blush', color: Color(0xFFEE9B8C), isPremium: true),
    CandleColorPreset(label: 'Ruby Tint', color: Color(0xFFD17A7A), isPremium: true),
    CandleColorPreset(label: 'Sage Cream', color: Color(0xFFBFD1B0), isPremium: true),
    CandleColorPreset(label: 'Mint Frost', color: Color(0xFFC5E1D7), isPremium: true),
    CandleColorPreset(label: 'Sky Powder', color: Color(0xFFB9CDE9), isPremium: true),
    CandleColorPreset(label: 'Amethyst', color: Color(0xFFC9A8D8), isPremium: true),
    CandleColorPreset(label: 'Obsidian Gold', color: Color(0xFF7F6A3A), isPremium: true),
    CandleColorPreset(label: 'Platinum Wax', color: Color(0xFFD8D8D1), isPremium: true),
    CandleColorPreset(label: 'Bronze Luxe', color: Color(0xFFB78A55), isPremium: true),
    CandleColorPreset(label: 'Crimson Red', color: Color(0xFFC62828), isPremium: true),
    CandleColorPreset(label: 'Royal Blue', color: Color(0xFF1E40AF), isPremium: true),
    CandleColorPreset(label: 'Emerald Green', color: Color(0xFF0F8A5F), isPremium: true),
    CandleColorPreset(label: 'Deep Violet', color: Color(0xFF6D28D9), isPremium: true),
    CandleColorPreset(label: 'Carbon Black', color: Color(0xFF1F1F1F), isPremium: true),
  ];

  static const List<BackgroundColorPreset> backgroundColors = [
    BackgroundColorPreset(
      label: 'Dark Navy',
      innerColor: Color(0xFF0A1428),
      outerColor: Color(0xFF1B2D4A),
      isPremium: false,
    ),
    BackgroundColorPreset(
      label: 'Warm Black',
      innerColor: Color(0xFF0F0A08),
      outerColor: Color(0xFF1A1410),
      isPremium: false,
    ),
    BackgroundColorPreset(
      label: 'Soft White',
      innerColor: Color(0xFFF5F0EB),
      outerColor: Color(0xFFE8DFD5),
      isPremium: false,
    ),
    BackgroundColorPreset(
      label: 'Forest Green',
      innerColor: Color(0xFF1A3B2E),
      outerColor: Color(0xFF2D5A47),
      isPremium: false,
    ),
    BackgroundColorPreset(
      label: 'Dusty Rose',
      innerColor: Color(0xFF3D2A2E),
      outerColor: Color(0xFF5A3D42),
      isPremium: false,
    ),
    BackgroundColorPreset(
      label: 'Deep Purple',
      innerColor: Color(0xFF2B1A3B),
      outerColor: Color(0xFF4A2E5F),
      isPremium: false,
    ),
    BackgroundColorPreset(
      label: 'Ember',
      innerColor: Color(0xFF2A1A0A),
      outerColor: Color(0xFF3A2410),
      isPremium: true,
    ),
    BackgroundColorPreset(
      label: 'Night',
      innerColor: Color(0xFF10131A),
      outerColor: Color(0xFF1B2230),
      isPremium: true,
    ),
    BackgroundColorPreset(
      label: 'Plum',
      innerColor: Color(0xFF20111F),
      outerColor: Color(0xFF351C33),
      isPremium: true,
    ),
    BackgroundColorPreset(
      label: 'Slate',
      innerColor: Color(0xFF17212B),
      outerColor: Color(0xFF273447),
      isPremium: true,
    ),
    BackgroundColorPreset(
      label: 'Ocean Deep',
      innerColor: Color(0xFF0B1E33),
      outerColor: Color(0xFF173B5E),
      isPremium: true,
    ),
    BackgroundColorPreset(
      label: 'Emerald Room',
      innerColor: Color(0xFF0F2A22),
      outerColor: Color(0xFF1E463A),
      isPremium: true,
    ),
    BackgroundColorPreset(
      label: 'Burgundy',
      innerColor: Color(0xFF2D1116),
      outerColor: Color(0xFF461921),
      isPremium: true,
    ),
    BackgroundColorPreset(
      label: 'Midnight Teal',
      innerColor: Color(0xFF10272B),
      outerColor: Color(0xFF1B454D),
      isPremium: true,
    ),
    BackgroundColorPreset(
      label: 'Royal Navy',
      innerColor: Color(0xFF111D3B),
      outerColor: Color(0xFF213B74),
      isPremium: true,
    ),
    BackgroundColorPreset(
      label: 'Chocolate',
      innerColor: Color(0xFF2B1A13),
      outerColor: Color(0xFF453124),
      isPremium: true,
    ),
    BackgroundColorPreset(
      label: 'Velvet Black',
      innerColor: Color(0xFF080808),
      outerColor: Color(0xFF161616),
      isPremium: true,
    ),
    BackgroundColorPreset(
      label: 'Champagne Noir',
      innerColor: Color(0xFF1B1610),
      outerColor: Color(0xFF30261B),
      isPremium: true,
    ),
    BackgroundColorPreset(
      label: 'Sapphire Luxe',
      innerColor: Color(0xFF101A39),
      outerColor: Color(0xFF1F3268),
      isPremium: true,
    ),
    BackgroundColorPreset(
      label: 'Jade Noir',
      innerColor: Color(0xFF12211A),
      outerColor: Color(0xFF223C31),
      isPremium: true,
    ),
  ];

  static List<CandleColorPreset> get freeCandleColors =>
      candleColors.where((preset) => !preset.isPremium).toList(growable: false);

  static List<BackgroundColorPreset> get freeBackgroundColors =>
      backgroundColors.where((preset) => !preset.isPremium).toList(growable: false);
}