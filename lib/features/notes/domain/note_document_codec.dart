import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';

class NoteDocumentCodec {
  static String encode(Document document) {
    return jsonEncode(document.toJson());
  }

  static Document decode(String contentJson) {
    if (contentJson.trim().isEmpty) {
      return Document.blank(withInitialText: true);
    }

    final decoded = jsonDecode(contentJson);
    if (decoded is! Map<String, dynamic>) {
      return Document.blank(withInitialText: true);
    }

    return Document.fromJson(decoded);
  }

  /// AI BACKGROUND CONTEXT HOOK
  ///
  /// Extrae texto plano de todos los nodos del documento recursivamente.
  /// Este stream está diseñado para alimentar el panel de IA en segundo plano
  /// sin bloquear el hilo principal de UI. Cada vez que el documento cambia
  /// via transaction, el hook produce el texto limpio concatenado.
  static String extractPlainText(Document document) {
    final buffer = StringBuffer();
    _extractTextRecursive(document.root, buffer);
    return buffer.toString().trim();
  }

  static void _extractTextRecursive(Node node, StringBuffer buffer) {
    final delta = node.delta;
    if (delta != null) {
      for (final op in delta) {
        if (op.data is String) {
          buffer.write(op.data as String);
          buffer.write(' ');
        }
      }
      buffer.write('\n');
    }
    for (final child in node.children) {
      _extractTextRecursive(child, buffer);
    }
  }
}
