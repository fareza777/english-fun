import 'package:flutter/material.dart';

class AppColors {
  static const ink = Color(0xFF2D3142);
  static const inkSoft = Color(0xFF4A4E69);
  static const skyTop = Color(0xFF7ED6FF);
  static const skyBottom = Color(0xFFEAF9FF);
  static const sun = Color(0xFFFFD60A);
  static const star = Color(0xFFFFB703);
  static const correct = Color(0xFF43AA8B);
  static const wrong = Color(0xFFEF476F);
}

class AppText {
  static const String _baloo = 'Baloo';
  static const String _nunito = 'Nunito';

  /// Bounds applied to the device font-size setting.
  ///
  /// The app's base type is already oversized for young readers, so scaling
  /// below 1.0 hurts rather than helps; the ceiling keeps chunky fixed-height
  /// controls (chips, app bars, answer buttons) from clipping their labels.
  static const double minTextScale = 1.0;
  static const double maxTextScale = 1.3;

  /// Bundled Noto Color Emoji so emojis look identical on every device,
  /// including old Android phones with missing glyphs.
  static const List<String> emojiFallback = ['AppEmoji'];

  /// Big playful display text (white with soft shadow, for colored backgrounds).
  static TextStyle display(double size, {Color color = Colors.white}) => TextStyle(
        fontFamily: _baloo,
        fontFamilyFallback: emojiFallback,
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.08,
        shadows: color == Colors.white
            ? const [Shadow(color: Color(0x55000000), blurRadius: 8, offset: Offset(0, 3))]
            : null,
      );

  /// Chunky heading on light backgrounds.
  static TextStyle heading(double size, {Color color = AppColors.ink}) => TextStyle(
        fontFamily: _baloo,
        fontFamilyFallback: emojiFallback,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.15,
      );

  /// Readable body text, always bold-ish for kids.
  static TextStyle body(double size, {Color color = AppColors.inkSoft}) => TextStyle(
        fontFamily: _nunito,
        fontFamilyFallback: emojiFallback,
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.3,
      );
}

/// Grade color identities.
class GradePalette {
  static const List<List<Color>> all = [
    [Color(0xFFFF6B6B), Color(0xFFFFA94D)], // Kelas 1 - coral
    [Color(0xFFFF8FAB), Color(0xFFC77DFF)], // Kelas 2 - pink purple
    [Color(0xFF2EC4B6), Color(0xFF80ED99)], // Kelas 3 - teal green
    [Color(0xFF4CC9F0), Color(0xFF4361EE)], // Kelas 4 - blue
    [Color(0xFFFF9F1C), Color(0xFFFFD60A)], // Kelas 5 - orange yellow
    [Color(0xFF9B5DE5), Color(0xFF5A189A)], // Kelas 6 - purple
  ];
}
