import 'dart:convert';
import 'dart:io';

import '../models/migration_models.dart';
import '../../../database/database_service.dart';
import '../../../../features/notes/domain/note_model.dart';
import '../../../../features/sheets/domain/sheet_block.dart';
import '../../../services/sync_manager.dart';

class NotionImporter {
  Future<MigrationResult> importExport(ImportConfig config, {void Function(MigrationProgress)? onProgress}) async {
    final rootDir = Directory(config.sourcePath);
    if (!await rootDir.exists()) {
      return MigrationResult(
        success: false,
        errors: ['Directory not found: ${config.sourcePath}'],
      );
    }

    final items = await rootDir.list().toList();
    int imported = 0;
    int skipped = 0;
    final errors = <String>[];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      onProgress?.call(MigrationProgress(
        total: items.length,
        completed: i,
        currentFile: item.path,
      ));

      try {
        if (item is File && item.path.endsWith('.md')) {
          await _importMarkdownPage(item, config);
          imported++;
        } else if (item is File && item.path.endsWith('.csv')) {
          await _importCsvDatabase(item, config);
          imported++;
        } else if (item is File && item.path.endsWith('.json')) {
          await _importJsonPage(item, config);
          imported++;
        }
      } catch (e) {
        errors.add('${item.path}: $e');
        skipped++;
      }
    }

    if (imported > 0) SyncManager.scheduleSync();

    return MigrationResult(
      success: errors.isEmpty,
      importedCount: imported,
      skippedCount: skipped,
      errors: errors,
      summary: 'Notion: $imported imported, $skipped skipped',
    );
  }

  Future<void> _importMarkdownPage(File file, ImportConfig config) async {
    final content = await file.readAsString();
    final lines = content.split('\n');
    final title = lines.isNotEmpty ? lines.first.replaceAll('#', '').trim() : file.uri.pathSegments.last.replaceAll('.md', '');
    final body = lines.skip(1).join('\n').trim();

    final note = NoteModel.create(title: title, contentJson: jsonEncode({'text': body}));
    await DatabaseService.saveNote(note);
  }

  Future<void> _importCsvDatabase(File file, ImportConfig config) async {
    final content = await file.readAsString();
    final rows = content.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (rows.isEmpty) return;

    final headers = _parseCsvRow(rows.first);
    final sheet = SheetBlock(columns: headers);

    for (int i = 1; i < rows.length; i++) {
      final cells = _parseCsvRow(rows[i]);
      sheet.addRow();
      for (int c = 0; c < cells.length && c < sheet.colCount; c++) {
        sheet.updateCell(i - 1, c, cells[c]);
      }
    }

    final fileName = file.uri.pathSegments.last.replaceAll('.csv', '');
    final note = NoteModel.create(title: 'Notion: $fileName', contentJson: sheet.encode());
    await DatabaseService.saveNote(note);
  }

  Future<void> _importJsonPage(File file, ImportConfig config) async {
    final raw = await file.readAsString();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final title = data['title'] as String? ?? data['id'] as String? ?? 'Imported';
    final note = NoteModel.create(title: title, contentJson: raw);
    await DatabaseService.saveNote(note);
  }

  List<String> _parseCsvRow(String line) {
    final result = <String>[];
    bool inQuotes = false;
    final buf = StringBuffer();
    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') { inQuotes = !inQuotes; continue; }
      if (c == ',' && !inQuotes) { result.add(buf.toString().trim()); buf.clear(); continue; }
      buf.write(c);
    }
    result.add(buf.toString().trim());
    return result;
  }
}
