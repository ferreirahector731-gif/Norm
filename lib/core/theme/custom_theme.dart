import 'dart:ui' show Color;
import 'package:flutter/painting.dart' show HSLColor;

import 'app_theme.dart';

class CustomNormTheme {
  final String id;
  final String name;
  final Color background;
  final Color surface;
  final Color card;
  final Color textMain;
  final Color accent;

  const CustomNormTheme({
    required this.id,
    required this.name,
    required this.background,
    required this.surface,
    required this.card,
    required this.textMain,
    required this.accent,
  });

  NormTheme toNormTheme() {
    final isDark = background.computeLuminance() < 0.5;
    final hsl = HSLColor.fromColor(accent);
    final accentGlow = accent.withOpacity(isDark ? 0.4 : 0.3);
    final textSub = Color.lerp(
      textMain,
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      0.55,
    )!;
    final borderColor = Color.lerp(
      isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      background,
      0.4,
    )!;

    return NormTheme(
      id: id,
      name: name,
      description: 'Tema personalizado',
      canvasBg: background,
      cardBg: card,
      borderColor: borderColor,
      textMain: textMain,
      textSub: textSub,
      accent: accent,
      accentGlow: accentGlow,
      cardRadius: 14,
      liquidBlur: isDark ? 20 : 12,
      brightness: isDark ? Brightness.dark : Brightness.light,
      fontFamily: null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'background': background.value,
        'surface': surface.value,
        'card': card.value,
        'textMain': textMain.value,
        'accent': accent.value,
      };

  factory CustomNormTheme.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];

    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('"id" debe ser un texto no vacío.');
    }
    if (id.length > 50) {
      throw const FormatException('"id" no puede superar los 50 caracteres.');
    }
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('"name" debe ser un texto no vacío.');
    }
    if (name.length > 50) {
      throw const FormatException('"name" no puede superar los 50 caracteres.');
    }

    int _parseColor(dynamic value, String field) {
      if (value is! int) {
        throw FormatException('"$field" debe ser un número entero.');
      }
      if (value < 0x00000000 || value > 0xFFFFFFFF) {
        throw FormatException(
          '"$field" (0x${value.toRadixString(16).toUpperCase()}) '
          'está fuera del rango válido 0x00000000 – 0xFFFFFFFF.',
        );
      }
      return value;
    }

    return CustomNormTheme(
      id: id.trim(),
      name: name.trim(),
      background: Color(_parseColor(json['background'], 'background')),
      surface: Color(_parseColor(json['surface'], 'surface')),
      card: Color(_parseColor(json['card'], 'card')),
      textMain: Color(_parseColor(json['textMain'], 'textMain')),
      accent: Color(_parseColor(json['accent'], 'accent')),
    );
  }
}
