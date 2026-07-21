import 'dart:collection';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  static const _modelName = 'gemini-1.5-flash-latest';
  static const _maxCacheSize = 50;

  final GenerativeModel _model;
  final LinkedHashMap<String, String> _cache = LinkedHashMap();

  AiService({required String apiKey})
      : _model = GenerativeModel(model: _modelName, apiKey: apiKey);

  String? _getCached(String key) => _cache[key];

  void _setCache(String key, String value) {
    _cache[key] = value;
    if (_cache.length > _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
  }

  Future<String> generate(String prompt, {bool useCache = true}) async {
    if (useCache) {
      final cached = _getCached(prompt);
      if (cached != null) return cached;
    }

    final response = await _model.generateContent([Content.text(prompt)]);
    final text = response.text ?? '';

    if (useCache) _setCache(prompt, text);
    return text;
  }

  Future<String> summarize(String text) =>
      generate('Resume el siguiente texto:\n$text');

  Future<String> suggestTags(String text) =>
      generate('Sugiere etiquetas para:\n$text');
}
