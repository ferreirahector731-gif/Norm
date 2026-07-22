import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OllamaException implements Exception {
  final String message;
  final int? statusCode;
  OllamaException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class OllamaService {
  final String baseUrl;
  final String model;
  final http.Client _client;
  final Duration timeout;

  OllamaService({
    this.baseUrl = 'http://localhost:11434',
    this.model = 'llama3.2',
    http.Client? client,
    this.timeout = const Duration(seconds: 60),
  }) : _client = client ?? http.Client();

  String get _generateUrl => '$baseUrl/api/generate';

  Stream<String> generateStream({
    required String prompt,
    String? systemPrompt,
  }) async* {
    final body = <String, dynamic>{
      'model': model,
      'prompt': systemPrompt != null ? '$systemPrompt\n\n$prompt' : prompt,
      'stream': true,
    };

    final uri = Uri.parse(_generateUrl);
    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(body);

    try {
      final response = await _client
          .send(request)
          .timeout(timeout);

      if (response.statusCode == 404) {
        yield* _errorStream(
          'Modelo "$model" no encontrado. Descárgalo con: ollama pull $model',
        );
        return;
      }

      if (response.statusCode != 200) {
        yield* _errorStream(
          'Ollama respondió con error ${response.statusCode}: ${response.reasonPhrase}',
        );
        return;
      }

      await for (final chunk
          in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
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
    } on TimeoutException {
      yield* _errorStream(
        'Ollama no respondió en ${timeout.inSeconds}s. '
        'Verifica que el servicio esté corriendo en $baseUrl',
      );
    } on http.ClientException catch (e) {
      yield* _errorStream(
        'No se pudo conectar a Ollama en $baseUrl.\n'
        'Asegúrate de que el servicio local esté encendido.\n'
        'Detalle: ${e.message}',
      );
    } catch (e) {
      yield* _errorStream('Error inesperado: $e');
    }
  }

  Stream<String> _errorStream(String message) async* {
    debugPrint('⚠️ OllamaService error: $message');
    yield '\n\n**[Error de conexión]**\n$message\n\n';
  }

  void dispose() {
    _client.close();
  }
}
