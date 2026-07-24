/*
 * Copyright (c) 2026 Norm Project. All rights reserved.
 * Licensed under the GNU Affero General Public License v3.0 (AGPLv3).
 */

import 'dart:convert';
import 'dart:io';

import '../models/migration_models.dart';
import '../../../database/database_service.dart';
import '../../../../features/notes/domain/note_model.dart';
import '../../../../features/sheets/domain/sheet_block.dart';
import '../../../services/sync_manager.dart';

class OfficeImporter {
  Future<MigrationResult> importFile(ImportConfig config, {void Function(MigrationProgress)? onProgress}) async {
    final file = File(config.sourcePath);
    if (!await file.exists()) {
      return MigrationResult(success: false, errors: ['File not found: ${config.sourcePath}']);
    }

    onProgress?.call(MigrationProgress(total: 1, completed: 0, currentFile: file.path));

    try {
      if (config.sourcePath.endsWith('.csv')) {
        await _importCsv(file, config);
      } else if (config.sourcePath.endsWith('.json')) {
        await _importJson(file, config);
      } else if (config.sourcePath.endsWith('.opml')) {
        await _importOpml(file, config);
      } else {
        return MigrationResult(success: false, errors: ['Unsupported format: ${config.sourcePath}']);
      }

      SyncManager.scheduleSync();
      return MigrationResult(success: true, importedCount: 1, summary: 'Imported: ${file.path}');
    } catch (e) {
      return MigrationResult(success: false, errors: ['${file.path}: $e']);
    }
  }

  Future<void> _importCsv(File file, ImportConfig config) async {
    final raw = await file.readAsString();
    final rows = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (rows.isEmpty) return;

    final headers = rows.first.split(',').map((h) => h.trim()).toList();
    final sheet = SheetBlock(columns: headers);
    for (int i = 1; i < rows.length; i++) {
      final cells = rows[i].split(',').map((c) => c.trim()).toList();
      sheet.addRow();
      for (int c = 0; c < cells.length && c < sheet.colCount; c++) {
        sheet.updateCell(i - 1, c, cells[c]);
      }
    }

    final name = file.uri.pathSegments.last.replaceAll('.csv', '');
    final note = NoteModel.create(title: name, contentJson: sheet.encode());
    await DatabaseService.saveNote(note);
  }

  Future<void> _importJson(File file, ImportConfig config) async {
    final raw = await file.readAsString();
    final data = jsonDecode(raw);
    final title = file.uri.pathSegments.last.replaceAll('.json', '');
    final note = NoteModel.create(title: title, contentJson: raw);
    await DatabaseService.saveNote(note);
  }

  Future<void> _importOpml(File file, ImportConfig config) async {
    final raw = await file.readAsString();
    final outlineRegex = RegExp(r'<outline\s+[^>]*text="([^"]*)"[^>]*/>');
    final matches = outlineRegex.allMatches(raw);
    final outlines = matches.map((m) => m.group(1)!).where((t) => t.isNotEmpty).toList();

    if (outlines.isEmpty) return;

    final note = NoteModel.create(
      title: file.uri.pathSegments.last.replaceAll('.opml', ''),
      contentJson: jsonEncode({'outlines': outlines}),
    );
    await DatabaseService.saveNote(note);
  }
}
