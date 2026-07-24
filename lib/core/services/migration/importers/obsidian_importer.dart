/*
 * Copyright (c) 2026 Norm Project. All rights reserved.
 * Licensed under the GNU Affero General Public License v3.0 (AGPLv3).
 */

import 'dart:convert';
import 'dart:io';

import '../models/migration_models.dart';
import '../../../database/database_service.dart';
import '../../../../features/notes/domain/note_model.dart';
import '../../../../features/links/domain/link_block.dart';
import '../../../services/sync_manager.dart';

class ObsidianImporter {
  final RegExp _wikilinkRegex = RegExp(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]');
  final RegExp _tagRegex = RegExp(r'#([\w\-/]+)');
  final RegExp _frontmatterRegex = RegExp(r'^---\n([\s\S]*?)\n---\n?');

  Future<MigrationResult> importVault(ImportConfig config, {void Function(MigrationProgress)? onProgress}) async {
    final rootDir = Directory(config.sourcePath);
    if (!await rootDir.exists()) {
      return MigrationResult(
        success: false,
        errors: ['Directory not found: ${config.sourcePath}'],
      );
    }

    final files = await rootDir
        .list(recursive: true)
        .where((e) => e is File && e.path.endsWith('.md'))
        .cast<File>()
        .toList();

    int imported = 0;
    int skipped = 0;
    final errors = <String>[];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      onProgress?.call(MigrationProgress(
        total: files.length,
        completed: i,
        currentFile: file.path,
      ));

      try {
        final content = await file.readAsString();
        final (title, body, frontmatter) = _parseMarkdown(file, content);
        final links = _extractWikilinks(body);
        final tags = _extractTags(body);
        final cleanBody = _removeWikilinks(body);

        if (config.dryRun) {
          skipped++;
          continue;
        }

        final note = NoteModel.create(
          title: title,
          contentJson: jsonEncode({
            'text': cleanBody,
            'frontmatter': frontmatter,
          }),
        );
        await DatabaseService.saveNote(note);

        if (config.createLinks && links.isNotEmpty) {
          final linkBlock = LinkBlock(title: 'Import: $title');
          for (final target in links) {
            linkBlock.addLink(0, label: target);
          }
          final linkNote = NoteModel.create(
            title: 'Links: $title',
            contentJson: linkBlock.encode(),
          );
          await DatabaseService.saveNote(linkNote);
        }

        imported++;
      } catch (e) {
        errors.add('${file.path}: $e');
        skipped++;
      }
    }

    if (imported > 0) {
      SyncManager.scheduleSync();
    }

    return MigrationResult(
      success: errors.isEmpty,
      importedCount: imported,
      skippedCount: skipped,
      errors: errors,
      summary: 'Obsidian: $imported imported, $skipped skipped',
    );
  }

  (String, String, Map<String, dynamic>) _parseMarkdown(File file, String content) {
    Map<String, dynamic> frontmatter = {};

    final fmMatch = _frontmatterRegex.firstMatch(content);
    if (fmMatch != null) {
      for (final line in fmMatch.group(1)!.split('\n')) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          frontmatter[parts[0].trim()] = parts.sublist(1).join(':').trim();
        }
      }
      content = content.replaceFirst(fmMatch.group(0)!, '');
    }

    final title = frontmatter['title'] as String? ??
        file.uri.pathSegments.last.replaceAll('.md', '');

    return (title, content.trim(), frontmatter);
  }

  List<String> _extractWikilinks(String text) {
    return _wikilinkRegex.allMatches(text).map((m) {
      final target = m.group(1)!.trim();
      final alias = m.group(2);
      return alias ?? target;
    }).toList();
  }

  List<String> _extractTags(String text) {
    return _tagRegex.allMatches(text).map((m) => m.group(1)!).toList();
  }

  String _removeWikilinks(String text) {
    return text.replaceAllMapped(_wikilinkRegex, (m) {
      return m.group(2) ?? m.group(1) ?? '';
    });
  }
}
