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

class CsvExporter {
  Future<List<ExportManifest>> exportSheets(String outputDir, String appVersion) async {
    final out = Directory(outputDir);
    if (!await out.exists()) await out.create(recursive: true);

    final notes = await DatabaseService.getAllNotes();
    final results = <ExportManifest>[];

    for (final note in notes) {
      if (detectNoteType(note) != 'sheet') continue;

      try {
        final block = SheetBlock.decode(note.contentJson);
        final csv = StringBuffer();
        csv.writeln(block.columns.join(','));
        for (final row in block.rows) {
          csv.writeln(row.map((c) => _escapeCsv(c)).join(','));
        }

        final safeName = note.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
        final path = '${out.path}/${safeName}.csv';
        await File(path).writeAsString(csv.toString());

        results.add(ExportManifest(
          exportedAt: DateTime.now(),
          appVersion: appVersion,
          noteCount: 1,
          moduleCounts: {'sheet': 1},
          archivePath: path,
        ));
      } catch (_) {}
    }

    return results;
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
