/*
 * Copyright (c) 2026 Norm Project. All rights reserved.
 * Licensed under the GNU Affero General Public License v3.0 (AGPLv3).
 */

import 'importers/obsidian_importer.dart';
import 'importers/notion_importer.dart';
import 'importers/office_importer.dart';
import 'exporters/markdown_exporter.dart';
import 'exporters/json_exporter.dart';
import 'exporters/csv_exporter.dart';
import 'liquid_data_sync.dart';
import 'models/migration_models.dart';
import '../../../features/notes/domain/note_model.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/sync_manager.dart';

class DataMigrationService {
  final ObsidianImporter obsidianImporter = ObsidianImporter();
  final NotionImporter notionImporter = NotionImporter();
  final OfficeImporter officeImporter = OfficeImporter();
  final MarkdownExporter markdownExporter = MarkdownExporter();
  final JsonExporter jsonExporter = JsonExporter();
  final CsvExporter csvExporter = CsvExporter();
  final LiquidDataSync liquidDataSync = LiquidDataSync();

  Future<MigrationResult> import(ImportConfig config, {void Function(MigrationProgress)? onProgress}) async {
    switch (config.source) {
      case ImportSource.obsidian:
        return obsidianImporter.importVault(config, onProgress: onProgress);
      case ImportSource.notion:
        return notionImporter.importExport(config, onProgress: onProgress);
      case ImportSource.csv:
      case ImportSource.opml:
      case ImportSource.json:
        return officeImporter.importFile(config, onProgress: onProgress);
    }
  }

  Future<ExportManifest> exportMarkdown(String outputDir, String appVersion) {
    return markdownExporter.exportAll(outputDir, appVersion);
  }

  Future<ExportManifest> exportJson(String outputPath, String appVersion) {
    return jsonExporter.exportDatabase(outputPath, appVersion);
  }

  Future<ExportManifest> exportCompressed(String outputPath, String appVersion) {
    return jsonExporter.exportCompressed(outputPath, appVersion);
  }

  Future<List<ExportManifest>> exportCsv(String outputDir, String appVersion) {
    return csvExporter.exportSheets(outputDir, appVersion);
  }

  Future<MigrationResult> reindexCrossReferences() async {
    try {
      final allNotes = await DatabaseService.getAllNotes();
      int updated = 0;

      for (final note in allNotes) {
        await liquidDataSync.ensureBlockConsistency(note);
        updated++;
      }

      SyncManager.scheduleSync();
      return MigrationResult(
        success: true,
        importedCount: updated,
        summary: 'Reindexed $updated notes for cross-module consistency',
      );
    } catch (e) {
      return MigrationResult(success: false, errors: ['Reindex failed: $e']);
    }
  }

  Future<MigrationResult> propagateChange(NoteModel updatedNote) async {
    try {
      await liquidDataSync.ensureBlockConsistency(updatedNote);
      liquidDataSync.propagateUpdate(updatedNote);
      return MigrationResult(success: true, importedCount: 1, summary: 'Change propagated for: ${updatedNote.title}');
    } catch (e) {
      return MigrationResult(success: false, errors: ['Propagation failed: $e']);
    }
  }
}
