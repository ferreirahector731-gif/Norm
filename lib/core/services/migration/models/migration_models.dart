import 'dart:convert';

import '../../../database/database_service.dart';
import '../../../../features/notes/domain/note_model.dart';
import '../../../../features/sheets/domain/sheet_block.dart';
import '../../../../features/charts/domain/chart_block.dart';
import '../../../../features/tasks/domain/task_block.dart';
import '../../../../features/links/domain/link_block.dart';

enum ImportSource { obsidian, notion, csv, json, opml }

enum ExportFormat { markdown, json, csv, pdf }

class MigrationProgress {
  final int total;
  final int completed;
  final String currentFile;
  final String? error;

  const MigrationProgress({
    required this.total,
    required this.completed,
    this.currentFile = '',
    this.error,
  });

  double get fraction => total > 0 ? completed / total : 0;
}

class MigrationResult {
  final bool success;
  final int importedCount;
  final int skippedCount;
  final List<String> errors;
  final String? summary;

  const MigrationResult({
    required this.success,
    this.importedCount = 0,
    this.skippedCount = 0,
    this.errors = const [],
    this.summary,
  });
}

class ExportManifest {
  final DateTime exportedAt;
  final String appVersion;
  final int noteCount;
  final Map<String, int> moduleCounts;
  final String archivePath;

  const ExportManifest({
    required this.exportedAt,
    required this.appVersion,
    required this.noteCount,
    required this.moduleCounts,
    required this.archivePath,
  });

  Map<String, dynamic> toJson() => {
        'exportedAt': exportedAt.toIso8601String(),
        'appVersion': appVersion,
        'noteCount': noteCount,
        'moduleCounts': moduleCounts,
        'archivePath': archivePath,
      };
}

class ImportConfig {
  final ImportSource source;
  final String sourcePath;
  final bool preserveIds;
  final bool createLinks;
  final bool dryRun;

  const ImportConfig({
    required this.source,
    required this.sourcePath,
    this.preserveIds = false,
    this.createLinks = true,
    this.dryRun = false,
  });
}

String detectNoteType(NoteModel note) {
  final raw = note.contentJson.trim();
  if (raw.startsWith('{"__norm_type__":"sheet"')) return 'sheet';
  if (raw.startsWith('{"__norm_type__":"chart"')) return 'chart';
  if (raw.startsWith('{"__norm_type__":"task"')) return 'task';
  if (raw.startsWith('{"__norm_type__":"link"')) return 'link';
  if (raw.startsWith('[')) return 'canvas';
  return 'note';
}
