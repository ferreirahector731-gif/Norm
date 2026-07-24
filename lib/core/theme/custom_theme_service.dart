import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'custom_theme.dart';

class CustomThemeService {
  static const _key = 'norm_custom_themes_v1';
  static List<CustomNormTheme> _cached = [];

  static Future<List<CustomNormTheme>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List<dynamic>;
      _cached = list
          .map((e) => CustomNormTheme.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _cached = [];
    }
    return List.unmodifiable(_cached);
  }

  static Future<void> save(CustomNormTheme theme) async {
    final existingIndex = _cached.indexWhere((t) => t.id == theme.id);
    if (existingIndex >= 0) {
      _cached[existingIndex] = theme;
    } else {
      _cached.add(theme);
    }
    await _persist();
  }

  static Future<void> delete(String id) async {
    _cached.removeWhere((t) => t.id == id);
    await _persist();
  }

  static List<CustomNormTheme> get current => List.unmodifiable(_cached);

  static String exportTheme(CustomNormTheme theme) {
    return jsonEncode(theme.toJson());
  }

  static CustomNormTheme importTheme(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El JSON importado no es un objeto válido.');
    }
    return CustomNormTheme.fromJson(decoded);
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_cached.map((t) => t.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}
