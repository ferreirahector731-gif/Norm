import 'dart:collection';

import '../../../../features/notes/domain/note_model.dart';
import '../../../../features/sheets/domain/sheet_block.dart';
import '../../../../features/charts/domain/chart_block.dart';
import '../../../../features/tasks/domain/task_block.dart';
import '../../../../features/links/domain/link_block.dart';
import '../../database/database_service.dart';

typedef SyncEventCallback = void Function(NoteModel updatedNote);

class LiquidDataSync {
  static final LiquidDataSync _instance = LiquidDataSync._();
  factory LiquidDataSync() => _instance;
  LiquidDataSync._();

  final _linkedNotes = LinkedHashMap<String, Set<String>>();
  final _listeners = <void Function()>[];

  void registerLink(String sourceNoteId, String targetNoteId) {
    _linkedNotes.putIfAbsent(sourceNoteId, () => {}).add(targetNoteId);
  }

  void unregisterNote(String noteId) {
    _linkedNotes.remove(noteId);
    for (final links in _linkedNotes.values) {
      links.remove(noteId);
    }
  }

  void propagateUpdate(NoteModel updatedNote) {
    final affected = <String>{updatedNote.id};
    for (final entry in _linkedNotes.entries) {
      if (entry.value.contains(updatedNote.id)) {
        affected.add(entry.key);
      }
    }

    for (final noteId in affected) {
      _notifyListeners();
    }
  }

  Future<void> ensureBlockConsistency(NoteModel note) async {
    final type = _detectBlockType(note);
    if (type == null) return;

    switch (type) {
      case 'chart':
        await _syncChartWithSheet(note);
      case 'task':
        await _syncTaskWithLink(note);
      case 'sheet':
        await _syncSheetWithChart(note);
    }
  }

  String? _detectBlockType(NoteModel note) {
    final trimmed = note.contentJson.trim();
    if (trimmed.startsWith('{"__norm_type__":"chart"')) return 'chart';
    if (trimmed.startsWith('{"__norm_type__":"task"')) return 'task';
    if (trimmed.startsWith('{"__norm_type__":"sheet"')) return 'sheet';
    return null;
  }

  Future<void> _syncChartWithSheet(NoteModel chartNote) async {
    try {
      final chart = ChartBlock.decode(chartNote.contentJson);
      final sheetSourceId = chart.linkedSheetId;
      if (sheetSourceId == null) return;

      final allNotes = await DatabaseService.getAllNotes();
      final sheetNote = allNotes.where((n) => n.id == sheetSourceId).firstOrNull;
      if (sheetNote == null) return;

      try {
        final sheet = SheetBlock.decode(sheetNote.contentJson);
        final rows = sheet.rows.where((r) => r.any((c) => c.isNotEmpty)).toList();
        chart.series.clear();
        for (int i = 0; i < sheet.colCount && i < rows.length; i++) {
          final name = sheet.columns.length > i ? sheet.columns[i] : 'Series $i';
          chart.series.add(ChartSeries(
            name: name,
            data: rows.map((r) => double.tryParse(r.length > i ? r[i] : '0') ?? 0).toList(),
          ));
        }
        chartNote.contentJson = chart.encode();
        await DatabaseService.saveNote(chartNote);
        propagateUpdate(chartNote);
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> _syncSheetWithChart(NoteModel sheetNote) async {
    try {
      final sheet = SheetBlock.decode(sheetNote.contentJson);
      final allNotes = await DatabaseService.getAllNotes();
      final linkedCharts = allNotes.where((n) {
        try {
          final c = ChartBlock.decode(n.contentJson);
          return c.linkedSheetId == sheetNote.id;
        } catch (_) {
          return false;
        }
      }).toList();

      for (final chartNote in linkedCharts) {
        await _syncChartWithSheet(chartNote);
      }
    } catch (_) {}
  }

  Future<void> _syncTaskWithLink(NoteModel taskNote) async {
    try {
      final task = TaskBlock.decode(taskNote.contentJson);
      final allNotes = await DatabaseService.getAllNotes();
      final linkNotes = allNotes.where((n) => n.title.contains(task.title)).toList();

      for (final linkNote in linkNotes) {
        registerLink(linkNote.id, taskNote.id);
        propagateUpdate(linkNote);
      }
    } catch (_) {}
  }

  void addListener(void Function() callback) {
    _listeners.add(callback);
  }

  void removeListener(void Function() callback) {
    _listeners.remove(callback);
  }

  void _notifyListeners() {
    for (final cb in _listeners) {
      try { cb(); } catch (_) {}
    }
  }

  void dispose() {
    _dbSubscription?.cancel();
    _listeners.clear();
    _linkedNotes.clear();
  }
}
