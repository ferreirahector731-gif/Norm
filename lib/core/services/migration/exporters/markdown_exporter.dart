/*
 * Copyright (c) 2026 Norm Project. All rights reserved.
 * Licensed under the GNU Affero General Public License v3.0 (AGPLv3).
 */

import 'dart:convert';
import 'dart:io';

import '../models/migration_models.dart';
import '../../../database/database_service.dart';
import '../../../../features/notes/domain/note_model.dart';

class MarkdownExporter {
  Future<ExportManifest> exportAll(String outputDir, String appVersion) async {
    final out = Directory(outputDir);
    if (!await out.exists()) await out.create(recursive: true);

    final notes = await DatabaseService.getAllNotes();
    int ex = 0;

    for (final note in notes) {
      final frontmatter = <String, String>{
        'title': note.title,
        'id': note.id.toString(),
        'created': note.createdAt.toIso8601String(),
        'updated': note.updatedAt.toIso8601String(),
        'type': detectNoteType(note),
      };

      final fmLines = frontmatter.entries.map((e) => '${e.key}: ${e.value}').join('\n');
      final safeName = _sanitizeFileName(note.title);
      final content = '---\n$fmLines\n---\n\n${_renderContent(note)}';

      await File('${out.path}/$safeName.md').writeAsString(content);
      ex++;
    }

    return ExportManifest(
      exportedAt: DateTime.now(),
      appVersion: appVersion,
      noteCount: ex,
      moduleCounts: {'notes': ex},
      archivePath: out.path,
    );
  }

  String _renderContent(NoteModel note) {
    try {
      final parsed = jsonDecode(note.contentJson);
      if (parsed is Map && parsed.containsKey('text')) return parsed['text'] as String;
      if (parsed is Map && parsed.containsKey('columns')) {
        final cols = (parsed['columns'] as List).join(' | ');
        return '| $cols |\n';
      }
      return note.contentJson;
    } catch (_) {
      return note.contentJson;
    }
  }

  String _sanitizeFileName(String title) {
    return title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').replaceAll(RegExp(r'\s+'), '_');
  }
}
