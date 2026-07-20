import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'chat_message_model.dart';
import 'ai_config.dart';

/// Posibles modos de respuesta del asistente.
enum AIReasoningMode { quick, reasoningX2 }

/// Adaptador unificado que convierte el historial de [ChatMessage] al formato
/// requerido por cada proveedor (OpenAI, Claude, Gemini, Ollama) y ejecuta
/// la inferencia.
class AIService {
  /// Envía un mensaje nuevo con historial completo al proveedor configurado.
  Stream<String> chat({
    required List<ChatMessage> history,
    required String newMessage,
    AIProvider? providerOverride,
    AIReasoningMode mode = AIReasoningMode.quick,
  }) async* {
    final config = AIConfigService.current;
    final provider = providerOverride ?? config.provider;
    final systemContent = _buildSystemPrompt(mode);

    switch (provider) {
      case AIProvider.localEmbedded:
        yield await _localEmbedded(newMessage);
      case AIProvider.ollamaLocal:
        yield* _ollamaChat(history, newMessage, systemContent);
      case AIProvider.externalAPI:
        yield* _openAIChat(history, newMessage, systemContent, config);
    }
  }

  /// Convierte el historial neutral al formato del proveedor indicado.
  List<Map<String, dynamic>> formatForProvider({
    required List<ChatMessage> messages,
    required AIProvider provider,
    String? systemPrompt,
  }) {
    switch (provider) {
      case AIProvider.ollamaLocal:
      case AIProvider.externalAPI:
        return _toOpenAIFormat(messages, systemPrompt);
      case AIProvider.localEmbedded:
        return _toOpenAIFormat(messages, systemPrompt);
    }
  }

  List<Map<String, dynamic>> _toOpenAIFormat(
    List<ChatMessage> messages,
    String? systemPrompt,
  ) {
    final result = <Map<String, dynamic>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      result.add({'role': 'system', 'content': systemPrompt});
    }
    for (final msg in messages) {
      result.add({
        'role': msg.role == MessageRole.assistant ? 'assistant' : 'user',
        'content': msg.content,
      });
    }
    return result;
  }

  String _buildSystemPrompt(AIReasoningMode mode) {
    final base = 'Eres un asistente de escritura literaria de alto nivel. '
        'Tu tono es sofisticado, prudente, adaptable y sumamente '
        'respetuoso con el estilo del autor.';
    if (mode == AIReasoningMode.reasoningX2) {
      return '$base\n\n'
          'IMPORTANTE: Antes de responder, analiza cuidadosamente el problema '
          'paso a paso. Escribe tu razonamiento interno entre etiquetas '
          '<thinking>...</thinking> y luego proporciona tu respuesta final. '
          'Duplica el esfuerzo de razonamiento para asegurar la máxima calidad.';
    }
    return base;
  }

  // ── Proveedores ──────────────────────────────────

  Future<String> _localEmbedded(String message) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return '**Simulación local**\n\nHas dicho: "$message"';
  }

  Stream<String> _ollamaChat(
    List<ChatMessage> history,
    String newMessage,
    String systemContent,
  ) async* {
    try {
      final messages = _toOpenAIFormat(history, systemContent);
      messages.add({'role': 'user', 'content': newMessage});

      final client = HttpClient();
      final request = await client.postUrl(
        Uri.parse('http://localhost:11434/api/chat'),
      );
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'model': 'llama3.2',
        'messages': messages,
        'stream': true,
      }));
      final response = await request.close().timeout(
        const Duration(seconds: 60),
      );
      await for (final raw in response.transform(utf8.decoder)) {
        for (final line in raw.split('\n')) {
          if (line.trim().isEmpty) continue;
          try {
            final parsed = jsonDecode(line);
            final text = parsed['message']?['content'] as String? ?? '';
            if (text.isNotEmpty) yield text;
          } catch (_) {}
        }
      }
    } catch (e) {
      yield '[Ollama] Error: $e';
    }
  }

  Stream<String> _openAIChat(
    List<ChatMessage> history,
    String newMessage,
    String systemContent,
    AIConfig config,
  ) async* {
    final endpoint =
        config.externalEndpoint ?? 'https://api.openai.com/v1/chat/completions';
    final apiKey = config.externalApiKey ?? '';
    try {
      final messages = _toOpenAIFormat(history, systemContent);
      messages.add({'role': 'user', 'content': newMessage});

      final client = HttpClient();
      final request = await client.postUrl(Uri.parse(endpoint));
      request.headers.contentType = ContentType.json;
      if (apiKey.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer $apiKey');
      }
      request.write(jsonEncode({
        'model': config.externalModel ?? 'gpt-4o-mini',
        'messages': messages,
      }));
      final response = await request.close().timeout(
        const Duration(seconds: 60),
      );
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      final text = decoded['choices']?[0]?['message']?['content'] as String? ??
          '[API] Respuesta vacía.';
      yield text;
    } catch (e) {
      yield '[ExternalAPI] Error: $e';
    }
  }
}
