import 'package:flutter/material.dart';

import 'custom_theme.dart';

enum NormThemeType {
  proDark,
  nordicWoods,
  espressoSepia,
  deepSpace,
  matchaZen,
  classicSlate,
  terminalCode,
  notionFluid,
}

class NormTheme {
  final String id;
  final String name;
  final String description;
  final Color canvasBg;
  final Color cardBg;
  final Color borderColor;
  final Color textMain;
  final Color textSub;
  final Color accent;
  final Color accentGlow;
  final double cardRadius;
  final double liquidBlur;
  final Brightness brightness;
  final String? fontFamily;

  const NormTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.canvasBg,
    required this.cardBg,
    required this.borderColor,
    required this.textMain,
    required this.textSub,
    required this.accent,
    required this.accentGlow,
    required this.cardRadius,
    required this.liquidBlur,
    required this.brightness,
    this.fontFamily,
  });

  double get innerRadius => cardRadius * 0.75;
  double get innerMostRadius => cardRadius * 0.5;
}

const _normThemes = <NormThemeType, NormTheme>{
  NormThemeType.proDark: NormTheme(
    id: 'pro-dark',
    name: 'Pro Dark',
    description: 'Linear / Vercel Liquid',
    canvasBg: Color(0xFF080710),
    cardBg: Color(0xFF12111A),
    borderColor: Color(0xFF232230),
    textMain: Color(0xFFF4F4F8),
    textSub: Color(0xFF8E8D9F),
    accent: Color(0xFF5E6AD2),
    accentGlow: Color(0x665E6AD2),
    cardRadius: 14,
    liquidBlur: 20,
    brightness: Brightness.dark,
  ),
  NormThemeType.nordicWoods: NormTheme(
    id: 'nordic-woods',
    name: 'Nordic Woods',
    description: 'Minimal Nord Soft',
    canvasBg: Color(0xFF2E3440),
    cardBg: Color(0xFF3B4252),
    borderColor: Color(0xFF4C566A),
    textMain: Color(0xFFECEFF4),
    textSub: Color(0xFFD8DEE9),
    accent: Color(0xFF88C0D0),
    accentGlow: Color(0x6688C0D0),
    cardRadius: 12,
    liquidBlur: 16,
    brightness: Brightness.dark,
  ),
  NormThemeType.espressoSepia: NormTheme(
    id: 'espresso-sepia',
    name: 'Espresso Sepia',
    description: 'Lectura Cálida',
    canvasBg: Color(0xFF151211),
    cardBg: Color(0xFF1E1A18),
    borderColor: Color(0xFF332D29),
    textMain: Color(0xFFF2E8DF),
    textSub: Color(0xFFA89B91),
    accent: Color(0xFFD4A373),
    accentGlow: Color(0x66D4A373),
    cardRadius: 16,
    liquidBlur: 20,
    brightness: Brightness.dark,
  ),
  NormThemeType.deepSpace: NormTheme(
    id: 'deep-space',
    name: 'Deep Space',
    description: 'GitHub Dark Monochrome',
    canvasBg: Color(0xFF0D1117),
    cardBg: Color(0xFF161B22),
    borderColor: Color(0xFF30363D),
    textMain: Color(0xFFF0F6FC),
    textSub: Color(0xFF8B949E),
    accent: Color(0xFF238636),
    accentGlow: Color(0x66238636),
    cardRadius: 12,
    liquidBlur: 16,
    brightness: Brightness.dark,
  ),
  NormThemeType.matchaZen: NormTheme(
    id: 'matcha-zen',
    name: 'Matcha Zen',
    description: 'Claro Anti-Fatiga',
    canvasBg: Color(0xFFF3F4F0),
    cardBg: Color(0xFFFFFFFF),
    borderColor: Color(0xFFE2E4DC),
    textMain: Color(0xFF1C2826),
    textSub: Color(0xFF52605D),
    accent: Color(0xFF52796F),
    accentGlow: Color(0x4D52796F),
    cardRadius: 16,
    liquidBlur: 12,
    brightness: Brightness.light,
  ),
  NormThemeType.classicSlate: NormTheme(
    id: 'classic-slate',
    name: 'Classic Slate',
    description: 'Corporativo / 2D Flat',
    canvasBg: Color(0xFF0F172A),
    cardBg: Color(0xFF1E293B),
    borderColor: Color(0xFF334155),
    textMain: Color(0xFFF8FAFC),
    textSub: Color(0xFF94A3B8),
    accent: Color(0xFF38BDF8),
    accentGlow: Color(0x6638BDF8),
    cardRadius: 4,
    liquidBlur: 0,
    brightness: Brightness.dark,
  ),
  NormThemeType.terminalCode: NormTheme(
    id: 'terminal-code',
    name: 'Terminal Code',
    description: 'Console / Hacker Mono',
    canvasBg: Color(0xFF05080A),
    cardBg: Color(0xFF0B1015),
    borderColor: Color(0xFF1E2D3D),
    textMain: Color(0xFF34D399),
    textSub: Color(0xFF10B981),
    accent: Color(0xFF34D399),
    accentGlow: Color(0x6634D399),
    cardRadius: 2,
    liquidBlur: 0,
    brightness: Brightness.dark,
    fontFamily: 'monospace',
  ),
  NormThemeType.notionFluid: NormTheme(
    id: 'notion-fluid',
    name: 'Notion Fluid',
    description: 'Espacial Indigo-Cian',
    canvasBg: Color(0xFF0B0F17),
    cardBg: Color(0xCC111827),
    borderColor: Color(0x4D6366F1),
    textMain: Color(0xFFF3F4F6),
    textSub: Color(0xFF9CA3AF),
    accent: Color(0xFF38BDF8),
    accentGlow: Color(0x8038BDF8),
    cardRadius: 16,
    liquidBlur: 24,
    brightness: Brightness.dark,
  ),
};

class ThemeProvider extends ChangeNotifier {
  NormThemeType _currentTheme = NormThemeType.proDark;
  CustomNormTheme? _activeCustomTheme;

  NormThemeType get currentTheme => _currentTheme;

  NormTheme get theme {
    if (_activeCustomTheme != null) return _activeCustomTheme!.toNormTheme();
    return _normThemes[_currentTheme]!;
  }

  CustomNormTheme? get activeCustomTheme => _activeCustomTheme;

  void setTheme(NormThemeType type) {
    _activeCustomTheme = null;
    _currentTheme = type;
    notifyListeners();
  }

  void setCustomTheme(CustomNormTheme customTheme) {
    _activeCustomTheme = customTheme;
    notifyListeners();
  }

  void clearCustomTheme() {
    _activeCustomTheme = null;
    notifyListeners();
  }

  ThemeData get themeData => _buildThemeData(theme);

  static final TextTheme _baseTextTheme = TextTheme(
    displayLarge: const TextStyle(letterSpacing: -1.5, height: 1.2),
    displayMedium: const TextStyle(letterSpacing: -0.5, height: 1.3),
    displaySmall: const TextStyle(letterSpacing: 0, height: 1.4),
    headlineLarge: TextStyle(letterSpacing: -0.5, height: 1.3, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(letterSpacing: -0.25, height: 1.35, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(letterSpacing: 0, height: 1.4, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(letterSpacing: 0, height: 1.45, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(letterSpacing: 0.15, height: 1.5, fontWeight: FontWeight.w500),
    titleSmall: TextStyle(letterSpacing: 0.1, height: 1.5, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(letterSpacing: 0.15, height: 1.6),
    bodyMedium: TextStyle(letterSpacing: 0.25, height: 1.6),
    bodySmall: TextStyle(letterSpacing: 0.4, height: 1.5),
    labelLarge: TextStyle(letterSpacing: 0.5, height: 1.5, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(letterSpacing: 0.5, height: 1.5, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(letterSpacing: 0.8, height: 1.5, fontWeight: FontWeight.w500),
  );

  static ThemeData _buildThemeData(NormTheme t) {
    final isDark = t.brightness == Brightness.dark;

    final textTheme = _baseTextTheme.apply(
      bodyColor: t.textSub,
      displayColor: t.textMain,
      fontFamily: t.fontFamily,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: t.brightness,
      scaffoldBackgroundColor: t.canvasBg,
      colorScheme: ColorScheme(
        brightness: t.brightness,
        primary: t.accent,
        onPrimary: isDark ? Colors.white : Colors.white,
        primaryContainer: t.accent.withOpacity(0.2),
        onPrimaryContainer: t.textMain,
        secondary: t.accent.withOpacity(0.8),
        onSecondary: t.textMain,
        secondaryContainer: t.cardBg,
        onSecondaryContainer: t.textMain,
        tertiary: t.textSub,
        onTertiary: t.textMain,
        error: const Color(0xFFEF4444),
        onError: Colors.white,
        surface: t.canvasBg,
        onSurface: t.textMain,
        surfaceContainerLowest: t.canvasBg,
        surfaceContainerLow: Color.lerp(t.canvasBg, t.cardBg, 0.3) ?? t.canvasBg,
        surfaceContainer: t.cardBg,
        surfaceContainerHigh: Color.lerp(t.cardBg, t.borderColor, 0.3) ?? t.cardBg,
        surfaceContainerHighest: t.borderColor,
        onSurfaceVariant: t.textSub,
        outline: t.borderColor,
        outlineVariant: t.borderColor.withOpacity(0.5),
        surfaceTint: t.accent,
        shadow: Colors.black.withOpacity(0.3),
        scrim: Colors.black38,
      ),
      textTheme: textTheme,
      dividerTheme: DividerThemeData(
        color: t.borderColor.withOpacity(0.6),
        thickness: 0.5,
      ),
      cardTheme: CardTheme(
        color: t.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.cardRadius),
          side: BorderSide(color: t.borderColor.withOpacity(0.5)),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: t.canvasBg,
        indicatorColor: t.accent.withOpacity(0.15),
        labelType: NavigationRailLabelType.none,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: t.accent,
          foregroundColor: isDark ? Colors.white : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(t.innerRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.innerRadius),
        ),
      ),
    );
  }
}

extension NormThemeExtension on NormThemeType {
  String get displayName => _normThemes[this]!.name;
  String get description => _normThemes[this]!.description;
  Color get swatchColor => _normThemes[this]!.accent;
  NormTheme get theme => _normThemes[this]!;
}
