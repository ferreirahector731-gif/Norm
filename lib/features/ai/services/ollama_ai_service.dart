import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class OllamaAIService {
  final String baseUrl;

  OllamaAIService({this.baseUrl = 'http://localhost:11434'});

  Stream<String> generateTextStream({
    required String prompt,
    String model = 'llama3.2',
  }) async* {
    final uri = Uri.parse('$baseUrl/api/generate');

    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'model': model,
        'prompt': prompt,
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
}
