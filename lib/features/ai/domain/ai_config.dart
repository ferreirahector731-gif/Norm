import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/ollama_service.dart';

enum AIProvider { localEmbedded, ollamaLocal, externalAPI }

enum AIReasoningMode { quick, reasoningX2 }

class AIConfig {
  final AIProvider provider;
  final String? externalApiKey;
  final String? externalEndpoint;
  final String? externalModel;
  final String? ollamaBaseUrl;
  final String? ollamaModel;

  const AIConfig({
    this.provider = AIProvider.ollamaLocal,
    this.externalApiKey,
    this.externalEndpoint,
    this.externalModel,
    this.ollamaBaseUrl,
    this.ollamaModel,
  });

  AIConfig copyWith({
    AIProvider? provider,
    String? externalApiKey,
    String? externalEndpoint,
    String? externalModel,
    String? ollamaBaseUrl,
    String? ollamaModel,
  }) =>
      AIConfig(
        provider: provider ?? this.provider,
        externalApiKey: externalApiKey ?? this.externalApiKey,
        externalEndpoint: externalEndpoint ?? this.externalEndpoint,
        externalModel: externalModel ?? this.externalModel,
        ollamaBaseUrl: ollamaBaseUrl ?? this.ollamaBaseUrl,
        ollamaModel: ollamaModel ?? this.ollamaModel,
      );

  Map<String, dynamic> toJson() => {
        'provider': provider.index,
        'externalApiKey': externalApiKey,
        'externalEndpoint': externalEndpoint,
        'externalModel': externalModel,
        if (ollamaBaseUrl != null) 'ollamaBaseUrl': ollamaBaseUrl,
        if (ollamaModel != null) 'ollamaModel': ollamaModel,
      };

  factory AIConfig.fromJson(Map<String, dynamic> json) => AIConfig(
        provider: AIProvider.values[json['provider'] as int? ?? 1],
        externalApiKey: json['externalApiKey'] as String?,
        externalEndpoint: json['externalEndpoint'] as String?,
        externalModel: json['externalModel'] as String?,
        ollamaBaseUrl: json['ollamaBaseUrl'] as String?,
        ollamaModel: json['ollamaModel'] as String?,
      );
}

class AIConfigService {
  static const _key = 'nota_ia_ai_config_v1';
  static AIConfig _cached = const AIConfig();

  static Future<AIConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      _cached = AIConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
    return _cached;
  }

  static Future<void> save(AIConfig config) async {
    _cached = config;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(config.toJson()));
  }

  static AIConfig get current => _cached;
}

class AIEngineService {
  static const String systemPrompt =
      'Eres un asistente de escritura literaria de alto nivel. '
      'Tu tono es sofisticado, prudente, adaptable y sumamente '
      'respetuoso con el estilo del autor. No inventes datos ni '
      'alteres el flujo del texto con jerga innecesaria a menos '
      'que se te solicite.';

  Stream<String> sendPromptStreaming(String userPrompt) async* {
    final config = AIConfigService.current;
    switch (config.provider) {
      case AIProvider.localEmbedded:
        yield await _localEmbeddedInference(userPrompt);
      case AIProvider.ollamaLocal:
        yield* _ollamaStreaming(userPrompt);
      case AIProvider.externalAPI:
        yield await _externalApiInference(userPrompt);
    }
  }

  Future<String> sendPrompt(String userPrompt) async {
    final buffer = StringBuffer();
    await for (final chunk in sendPromptStreaming(userPrompt)) {
      buffer.write(chunk);
    }
    return buffer.toString();
  }

  Future<String> _localEmbeddedInference(String prompt) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return '**Respuesta simulada local**\n\n'
        'Has escrito: "$prompt"\n\n'
        'Este es un texto generado por el motor LocalEmbedded. '
        'Para activar la IA real, configura Ollama o una API externa '
        'en Ajustes \u2192 Motor de IA.';
  }

  Stream<String> _ollamaStreaming(String prompt) async* {
    final config = AIConfigService.current;
    final service = OllamaService(
      baseUrl: config.ollamaBaseUrl ?? 'http://localhost:11434',
      model: config.ollamaModel ?? 'llama3.2',
    );
    try {
      await for (final chunk in service.generateStream(
        prompt: prompt,
        systemPrompt: systemPrompt,
      )) {
        yield chunk;
      }
    } finally {
      service.dispose();
    }
  }

  Future<String> _externalApiInference(String prompt) async {
    final config = AIConfigService.current;
    final endpoint =
        config.externalEndpoint ?? 'https://api.openai.com/v1/chat/completions';
    final apiKey = config.externalApiKey ?? '';
    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse(endpoint));
      request.headers.contentType = ContentType.json;
      if (apiKey.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer $apiKey');
      }
      request.write(jsonEncode({
        'model': config.externalModel ?? 'gpt-4o-mini',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': prompt},
        ],
      }));
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      return decoded['choices']?[0]?['message']?['content'] as String? ??
          '[API] Respuesta vacía.';
    } catch (e) {
      return '[ExternalAPI] Error: $e';
    }
  }
}
