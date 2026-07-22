import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';

class MarkdownConverter {
  /// Convierte el [contentJson] de AppFlowy y [title] a una cadena Markdown.
  static String noteToMarkdown(String title, String contentJson) {
    final buf = StringBuffer();
    buf.writeln('# $title');
    buf.writeln('');

    if (contentJson.trim().startsWith('[')) {
      // Whiteboard — no se puede convertir a texto plano
      buf.writeln('*[Pizarrón — contenido visual no exportable a Markdown]*');
      return buf.toString();
    }

    try {
      final document = NoteDocumentCodec.decode(contentJson);
      final text = NoteDocumentCodec.extractPlainText(document);
      buf.write(text.trim());
    } catch (_) {
      buf.write(contentJson);
    }

    return buf.toString();
  }

  /// Parsea un archivo Markdown y devuelve (título, cuerpo).
  static (String title, String body) parseMarkdown(String content) {
    final lines = content.split('\n');
    String title = 'Nota importada';
    int bodyStart = 0;

    // La primera línea con # es el título
    for (int i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (trimmed.startsWith('# ')) {
        title = trimmed.substring(2).trim();
        bodyStart = i + 1;
        break;
      }
    }

    final body = lines.sublist(bodyStart).join('\n').trim();
    return (title, body);
  }

  /// Convierte texto plano al formato JSON de documento AppFlowy.
  static String plainTextToContentJson(String body) {
    final delta = Delta()..insert(body);
    final page = {
      'document': {
        'type': 'page',
        'children': [
          {
            'type': 'paragraph',
            'delta': delta.toJson(),
          },
        ],
      },
    };
    return jsonEncode(page);
  }
}
