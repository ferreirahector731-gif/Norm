/*
 * Copyright (c) 2026 Norm Project. All rights reserved.
 * Licensed under the GNU Affero General Public License v3.0 (AGPLv3).
 */

import 'dart:convert';
import 'dart:io';

import '../models/migration_models.dart';
import '../../../database/database_service.dart';

class JsonExporter {
  Future<ExportManifest> exportDatabase(String outputPath, String appVersion) async {
    final notes = await DatabaseService.getAllNotes();
    final data = {
      'appVersion': appVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'notes': notes.map((n) => _noteToJson(n)).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final file = File(outputPath);
    await file.writeAsString(jsonStr);

    return ExportManifest(
      exportedAt: DateTime.now(),
      appVersion: appVersion,
      noteCount: notes.length,
      moduleCounts: {'notes': notes.length},
      archivePath: file.path,
    );
  }

  Future<ExportManifest> exportCompressed(String outputPath, String appVersion) async {
    final notes = await DatabaseService.getAllNotes();
    final jsonBytes = utf8.encode(const JsonEncoder.withIndent(' ').convert({
      'appVersion': appVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'notes': notes.map((n) => _noteToJson(n)).toList(),
    }));

    final compressed = gzip.encode(jsonBytes);
    final file = File(outputPath);
    await file.writeAsBytes(compressed);

    return ExportManifest(
      exportedAt: DateTime.now(),
      appVersion: appVersion,
      noteCount: notes.length,
      moduleCounts: {'notes': notes.length},
      archivePath: file.path,
    );
  }

  Map<String, dynamic> _noteToJson(dynamic note) {
    return {
      'id': note.id,
      'title': note.title,
      'contentJson': note.contentJson,
      'createdAt': note.createdAt.toIso8601String(),
      'updatedAt': note.updatedAt.toIso8601String(),
      'isDirty': note.isDirty,
      'remoteId': note.remoteId,
      'lastSyncedAt': note.lastSyncedAt?.toIso8601String(),
    };
  }
}
