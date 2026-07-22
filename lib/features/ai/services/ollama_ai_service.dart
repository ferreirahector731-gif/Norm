import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class GeneratedBlock {
  final String type;
  final String content;
  final List<String> properties;
  final int position;

  GeneratedBlock({
    required this.type,
    required this.content,
    this.properties = const [],
    this.position = 0,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'content': content,
        'properties': properties,
        'position': position,
      };
}

class OllamaAIService {
  final String baseUrl;
  final bool enableWebSearch;

  OllamaAIService({this.baseUrl = 'http://localhost:11434', this.enableWebSearch = false});

  /// Stream simple de texto generado.
  Stream<String> generateTextStream({
    required String prompt,
    String model = 'llama3.2',
    String? whiteboardContext,
  }) async* {
    final fullPrompt = whiteboardContext != null
        ? 'Contexto del pizarrón:\n$whiteboardContext\n\n---\n\n$prompt'
        : prompt;

    final uri = Uri.parse('$baseUrl/api/generate');
    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'model': model,
        'prompt': fullPrompt,
        'stream': true,
      });

    try {
      final response = await request.send();
      if (response.statusCode != 200) {
        yield 'Error: ${response.statusCode} — ${response.reasonPhrase}';
        return;
      }

      await for (final chunk in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (chunk.trim().isEmpty) continue;
        try {
          final json = jsonDecode(chunk) as Map<String, dynamic>;
          final token = json['response'] as String? ?? '';
          if (token.isNotEmpty) yield token;
          if (json['done'] == true) break;
        } catch (_) {
          continue;
        }
      }
    } catch (e) {
      yield 'Error de conexión con Ollama: $e';
    }
  }

  /// Genera una respuesta estructurada en bloques a partir de un prompt
  /// y elementos contextuales del pizarrón.
  Stream<GeneratedBlock> generateStructuredBlocks({
    required String prompt,
    List<String> whiteboardElements = const [],
    String model = 'llama3.2',
  }) async* {
    final systemPrompt = _buildBlockSystemPrompt(whiteboardElements);
    final fullPrompt = '$systemPrompt\n\n$prompt';

    final uri = Uri.parse('$baseUrl/api/generate');
    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'model': model,
        'prompt': fullPrompt,
        'stream': true,
        'format': 'json',
      });

    try {
      final response = await request.send();
      if (response.statusCode != 200) {
        yield GeneratedBlock(type: 'error', content: 'Error ${response.statusCode}: ${response.reasonPhrase}');
        return;
      }

      final buffer = StringBuffer();
      await for (final chunk in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (chunk.trim().isEmpty) continue;
        try {
          final json = jsonDecode(chunk) as Map<String, dynamic>;
          final token = json['response'] as String? ?? '';
          buffer.write(token);
          if (json['done'] == true) break;
        } catch (_) {
          continue;
        }
      }

      final raw = buffer.toString().trim();
      if (raw.isEmpty) {
        yield GeneratedBlock(type: 'text', content: '(sin respuesta)');
        return;
      }

      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              yield GeneratedBlock(
                type: item['type'] as String? ?? 'text',
                content: item['content'] as String? ?? '',
                properties: _parseList(item['properties']),
                position: item['position'] as int? ?? 0,
              );
            }
          }
        } else if (decoded is Map<String, dynamic>) {
          yield GeneratedBlock(
            type: decoded['type'] as String? ?? 'text',
            content: decoded['content'] as String? ?? '',
            properties: _parseList(decoded['properties']),
            position: decoded['position'] as int? ?? 0,
          );
        }
      } catch (_) {
        yield GeneratedBlock(type: 'text', content: raw);
      }
    } catch (e) {
      yield GeneratedBlock(type: 'error', content: 'Error de conexión: $e');
    }
  }

  /// Stream con modo de búsqueda enriquecida.
  /// Cuando [enableWebSearch] es true, el sistema prompt indica a la IA
  /// que puede solicitar datos actualizados vía web. El flag es puramente
  /// semántico — la IA genera consultas que la UI puede interceptar.
  Stream<String> generateRichSearchStream({
    required String prompt,
    String? whiteboardContext,
    String model = 'llama3.2',
  }) async* {
    final systemPrompt = StringBuffer();
    systemPrompt.writeln('Eres un asistente con capacidad de búsqueda enriquecida.');
    if (enableWebSearch) {
      systemPrompt.writeln('Tienes acceso a búsqueda web. Si necesitas información actualizada,');
      systemPrompt.writeln('responde con una consulta de búsqueda en este formato:');
      systemPrompt.writeln('[SEARCH: tu consulta aquí]');
      systemPrompt.writeln('y luego continúa tu respuesta normalmente.');
    } else {
      systemPrompt.writeln('Trabajas completamente sin conexión.');
      systemPrompt.writeln('Usas solo tu conocimiento interno para responder.');
    }
    systemPrompt.writeln('Responde en español de forma clara y concisa.');

    final fullPrompt = StringBuffer();
    fullPrompt.writeln(systemPrompt.toString());
    if (whiteboardContext != null) {
      fullPrompt.writeln('\nContexto del pizarrón:\n$whiteboardContext');
    }
    fullPrompt.writeln('\n---\n');
    fullPrompt.writeln(prompt);

    final uri = Uri.parse('$baseUrl/api/generate');
    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'model': model,
        'prompt': fullPrompt.toString(),
        'stream': true,
      });

    try {
      final response = await request.send();
      if (response.statusCode != 200) {
        yield 'Error: ${response.statusCode} — ${response.reasonPhrase}';
        return;
      }

      await for (final chunk in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (chunk.trim().isEmpty) continue;
        try {
          final json = jsonDecode(chunk) as Map<String, dynamic>;
          final token = json['response'] as String? ?? '';
          if (token.isNotEmpty) yield token;
          if (json['done'] == true) break;
        } catch (_) {
          continue;
        }
      }
    } catch (e) {
      yield 'Error de conexión con Ollama: $e';
    }
  }

  String _buildBlockSystemPrompt(List<String> whiteboardElements) {
    final buf = StringBuffer();
    buf.writeln('Eres un asistente que genera datos estructurados en formato JSON.');
    buf.writeln('Siempre respondes ÚNICAMENTE con un array de objetos JSON, sin texto adicional.');
    buf.writeln('Cada objeto tiene esta forma:');
    buf.writeln('  {"type": "text|card|table|list|code|image", "content": "...", "properties": [...], "position": 0}');

    if (whiteboardElements.isNotEmpty) {
      buf.writeln('\nElementos del pizarrón disponibles:');
      for (final el in whiteboardElements) {
        buf.writeln('  - $el');
      }
      buf.writeln('Interpreta estos elementos y genera nuevos bloques relacionados.');
    }

    buf.writeln('\nGenera entre 1 y 5 bloques según lo que solicite el usuario.');
    return buf.toString();
  }

  List<String> _parseList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }
}
