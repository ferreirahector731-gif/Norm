import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/services/migration/data_migration_service.dart';
import '../../../core/services/migration/models/migration_models.dart';
import '../../../core/theme/app_theme.dart';

class MigrationSection extends StatefulWidget {
  const MigrationSection({super.key});

  @override
  State<MigrationSection> createState() => _MigrationSectionState();
}

class _MigrationSectionState extends State<MigrationSection> {
  final _service = DataMigrationService();
  String _status = '';
  bool _busy = false;

  Future<void> _importObsidian() async {
    final dir = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select Obsidian Vault');
    if (dir == null) return;
    await _runImport(ImportConfig(source: ImportSource.obsidian, sourcePath: dir));
  }

  Future<void> _importNotion() async {
    final dir = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select Notion Export Folder');
    if (dir == null) return;
    await _runImport(ImportConfig(source: ImportSource.notion, sourcePath: dir));
  }

  Future<void> _importFile(ImportSource source) async {
    final ext = source == ImportSource.csv ? 'csv' : source == ImportSource.json ? 'json' : 'opml';
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [ext],
      dialogTitle: 'Select .$ext file',
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    await _runImport(ImportConfig(source: source, sourcePath: path));
  }

  Future<void> _runImport(ImportConfig config) async {
    setState(() { _busy = true; _status = 'Importing...'; });
    final result = await _service.import(config, onProgress: (p) {
      setState(() { _status = '${p.completed}/${p.total}: ${p.currentFile}'; });
    });
    setState(() {
      _busy = false;
      _status = result.success
          ? '✅ ${result.importedCount} imported, ${result.skippedCount} skipped'
          : '❌ ${result.errors.length} error(s)';
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_status),
      backgroundColor: result.success ? Colors.green.shade700 : Colors.red.shade700,
    ));
  }

  Future<void> _exportMarkdown() async {
    final dir = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Export to Markdown');
    if (dir == null) return;
    setState(() { _busy = true; _status = 'Exporting...'; });
    final manifest = await _service.exportMarkdown(dir, '1.8.0');
    setState(() { _busy = false; _status = '✅ Exported ${manifest.noteCount} notes'; });
  }

  Future<void> _exportJson() async {
    final dir = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Export JSON');
    if (dir == null) return;
    setState(() { _busy = true; _status = 'Exporting...'; });
    final manifest = await _service.exportCompressed('${dir}/norm_export.json.gz', '1.8.0');
    setState(() { _busy = false; _status = '✅ Exported ${manifest.noteCount} notes'; });
  }

  Future<void> _reindex() async {
    setState(() { _busy = true; _status = 'Reindexing...'; });
    final result = await _service.reindexCrossReferences();
    setState(() { _busy = false; _status = result.summary ?? 'Done'; });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MIGRACIÓN', style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: scheme.outline,
        )),
        const SizedBox(height: 8),
        _ActionChip(label: 'Import Obsidian', icon: Icons.file_copy, onTap: _busy ? null : _importObsidian),
        const SizedBox(height: 6),
        _ActionChip(label: 'Import Notion', icon: Icons.folder_open, onTap: _busy ? null : _importNotion),
        const SizedBox(height: 6),
        _ActionChip(label: 'Import CSV', icon: Icons.table_chart, onTap: _busy ? null : () => _importFile(ImportSource.csv)),
        const SizedBox(height: 6),
        _ActionChip(label: 'Import JSON', icon: Icons.data_object, onTap: _busy ? null : () => _importFile(ImportSource.json)),
        const SizedBox(height: 14),
        _ActionChip(label: 'Export MD', icon: Icons.description, onTap: _busy ? null : _exportMarkdown),
        const SizedBox(height: 6),
        _ActionChip(label: 'Export JSON (.gz)', icon: Icons.archive, onTap: _busy ? null : _exportJson),
        const SizedBox(height: 14),
        _ActionChip(label: 'Reindex Cross-Refs', icon: Icons.sync, onTap: _busy ? null : _reindex),
        if (_status.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_status, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        ],
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _ActionChip({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant.withOpacity(0.15), width: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: scheme.primary),
                const SizedBox(width: 10),
                Text(label, style: TextStyle(fontSize: 13, color: onTap == null ? scheme.outline : scheme.onSurface)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
