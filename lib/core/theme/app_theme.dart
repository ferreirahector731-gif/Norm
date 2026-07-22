import 'package:flutter/material.dart';

enum ThemeModeType { light, dark, sepia }

class ThemeProvider extends ChangeNotifier {
  ThemeModeType _currentTheme = ThemeModeType.dark;

  ThemeModeType get currentTheme => _currentTheme;

  void setTheme(ThemeModeType theme) {
    _currentTheme = theme;
    notifyListeners();
  }

  ThemeData get themeData {
    switch (_currentTheme) {
      case ThemeModeType.light:
        return _lightTheme;
      case ThemeModeType.sepia:
        return _sepiaTheme;
      case ThemeModeType.dark:
      default:
        return _darkTheme;
    }
  }

  static const _accentBlue = Color(0xFF3B82F6);

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

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF090D16),
    colorScheme: const ColorScheme.dark(
      surface: Color(0xFF090D16),
      surfaceContainerLow: Color(0xFF111622),
      surfaceContainer: Color(0xFF131B2E),
      surfaceContainerHigh: Color(0xFF1A2340),
      surfaceContainerHighest: Color(0xFF222D4A),
      primary: _accentBlue,
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFF1E3A6B),
      onPrimaryContainer: Color(0xFFD6E4FF),
      secondary: Color(0xFF60A5FA),
      onSecondary: Color(0xFF0F1A35),
      secondaryContainer: Color(0xFF1A3361),
      onSecondaryContainer: Color(0xFFD6E4FF),
      tertiary: Color(0xFF38BDF8),
      error: Color(0xFFEF4444),
      onError: Color(0xFFFFFFFF),
      surfaceTint: _accentBlue,
      outline: Color(0xFF2D3A5A),
      outlineVariant: Color(0xFF1E2A44),
    ),
    textTheme: _baseTextTheme.apply(
      bodyColor: const Color(0xFF94A3B8),
      displayColor: const Color(0xFFF8FAFC),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white.withOpacity(0.06),
      thickness: 0.5,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF131B2E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: const Color(0xFF090D16),
      indicatorColor: _accentBlue.withOpacity(0.15),
      labelType: NavigationRailLabelType.none,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _accentBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xffF5F5F0),
    colorScheme: const ColorScheme.light(
      surface: Color(0xffFFFFFF),
      surfaceContainerLow: Color(0xffF0EFEC),
      surfaceContainer: Color(0xffE8E7E3),
      primary: const Color(0xff7B2CBF),
      onPrimary: Color(0xffFFFFFF),
      primaryContainer: Color(0xffEDE0FF),
      onPrimaryContainer: Color(0xff2E0056),
      secondary: Color(0xff6B4F7A),
      onSecondary: Color(0xffFFFFFF),
      secondaryContainer: Color(0xffF5E4FF),
      onSecondaryContainer: Color(0xff250B34),
      error: Color(0xffDC2626),
      onError: Color(0xffFFFFFF),
      surfaceTint: const Color(0xff7B2CBF),
      outline: Color(0xffC2C1BC),
      outlineVariant: Color(0xffD6D5D0),
    ),
    textTheme: _baseTextTheme.apply(
      bodyColor: const Color(0xff1A1A1E),
      displayColor: const Color(0xff0B0B0F),
    ),
    dividerTheme: DividerThemeData(
      color: const Color(0xff000000).withOpacity(0.06),
      thickness: 0.5,
    ),
    cardTheme: CardTheme(
      color: const Color(0xffFFFFFF),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xff7B2CBF),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  static final ThemeData _sepiaTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xffF4ECD8),
    colorScheme: const ColorScheme.light(
      surface: Color(0xffF4ECD8),
      surfaceContainerLow: Color(0xffEBE2CC),
      surfaceContainer: Color(0xffE0D6BE),
      primary: Color(0xff8C6239),
      onPrimary: Color(0xffFFFFFF),
      primaryContainer: Color(0xffEAD7C0),
      onPrimaryContainer: Color(0xFF3D280E),
      secondary: Color(0xffA0805A),
      onSecondary: Color(0xffFFFFFF),
      secondaryContainer: Color(0xffF0E2CC),
      onSecondaryContainer: Color(0xff372711),
      error: Color(0xffC93A3A),
      onError: Color(0xffFFFFFF),
      surfaceTint: Color(0xff8C6239),
      outline: Color(0xffCCC3B0),
      outlineVariant: Color(0xffDBD3C2),
    ),
    textTheme: _baseTextTheme.apply(
      bodyColor: const Color(0xff2C2418),
      displayColor: const Color(0xff1C160E),
    ),
    dividerTheme: DividerThemeData(
      color: const Color(0xff000000).withOpacity(0.08),
      thickness: 0.5,
    ),
    cardTheme: CardTheme(
      color: const Color(0xffF4ECD8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xff8C6239),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
