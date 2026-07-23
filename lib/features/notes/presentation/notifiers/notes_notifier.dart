import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

import '../../domain/markdown_converter.dart';
import '../../domain/note_model.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/services/sync_manager.dart';
import '../../../sheets/domain/sheet_block.dart';
import '../../../charts/domain/chart_block.dart';
import '../../../tasks/domain/task_block.dart';
import '../../../links/domain/link_block.dart';

class NotesNotifier extends ChangeNotifier {
  List<NoteModel> _notes = [];
  NoteModel? _activeNote;
  bool _isLoading = true;

  List<NoteModel> get notes => _notes;
  NoteModel? get activeNote => _activeNote;
  bool get isLoading => _isLoading;

  Future<void> loadNotes({NoteModel? initialNote}) async {
    _isLoading = true;
    notifyListeners();

    final notes = await DatabaseService.getAllNotes();
    _notes = notes;

    NoteModel? targetNote;

    if (initialNote != null) {
      targetNote = notes.cast<NoteModel?>().firstWhere(
        (n) => n!.id == initialNote.id,
        orElse: () => null,
      );
    }

    if (targetNote == null && notes.isNotEmpty) {
      targetNote = notes.first;
    }

    if (targetNote == null) {
      final welcomeNote = NoteModel.create(
        title: 'Bienvenido a Norm',
        contentJson: '[]',
      );
      await DatabaseService.saveNote(welcomeNote);
      SyncManager.scheduleSync();
      _notes = [welcomeNote];
      _activeNote = welcomeNote;
    } else {
      _activeNote = targetNote;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createTextNote() async {
    final note = NoteModel.create(
      title: 'Nota sin título',
      contentJson: '[]',
    );
    await DatabaseService.saveNote(note);
    SyncManager.scheduleSync();

    _notes = await DatabaseService.getAllNotes();
    _activeNote = note;
    notifyListeners();
  }

  Future<void> createWhiteboard() async {
    final note = NoteModel.create(
      title: 'Pizarrón sin título',
      contentJson: '[]',
    );
    await DatabaseService.saveNote(note);
    SyncManager.scheduleSync();

    _notes = await DatabaseService.getAllNotes();
    _activeNote = note;
    notifyListeners();
  }

  Future<void> createSheet() async {
    final sheet = SheetBlock();
    final note = NoteModel.create(
      title: 'Hoja sin título',
      contentJson: sheet.encode(),
    );
    await DatabaseService.saveNote(note);
    SyncManager.scheduleSync();

    _notes = await DatabaseService.getAllNotes();
    _activeNote = note;
    notifyListeners();
  }

  Future<void> createChart() async {
    final chart = ChartBlock();
    final note = NoteModel.create(
      title: 'Gráfico sin título',
      contentJson: chart.encode(),
    );
    await DatabaseService.saveNote(note);
    SyncManager.scheduleSync();

    _notes = await DatabaseService.getAllNotes();
    _activeNote = note;
    notifyListeners();
  }

  Future<void> createTask() async {
    final block = TaskBlock();
    final note = NoteModel.create(
      title: 'Lista de Tareas',
      contentJson: block.encode(),
    );
    await DatabaseService.saveNote(note);
    SyncManager.scheduleSync();

    _notes = await DatabaseService.getAllNotes();
    _activeNote = note;
    notifyListeners();
  }

  Future<void> createLink() async {
    final block = LinkBlock();
    final note = NoteModel.create(
      title: 'Conexiones',
      contentJson: block.encode(),
    );
    await DatabaseService.saveNote(note);
    SyncManager.scheduleSync();

    _notes = await DatabaseService.getAllNotes();
    _activeNote = note;
    notifyListeners();
  }

  void selectNote(NoteModel note) {
    _activeNote = note;
    notifyListeners();
  }

  Future<void> updateNote(NoteModel note) async {
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx >= 0) {
      _notes[idx] = note;
    }
    if (_activeNote?.id == note.id) {
      _activeNote = note;
    }
    await DatabaseService.saveNote(note);
    SyncManager.scheduleSync();
    notifyListeners();
  }

  Future<void> deleteNote(int id) async {
    if (_notes.length <= 1) return;

    await DatabaseService.deleteNote(id);
    _notes = await DatabaseService.getAllNotes();

    if (_activeNote?.id == id) {
      _activeNote = _notes.isNotEmpty ? _notes.first : null;
    }
    notifyListeners();
  }

  // ── Export / Import ────────────────────────────

  /// Exporta la nota activa como archivo .md usando el selector nativo.
  Future<String?> exportCurrentNoteAsMarkdown() async {
    final note = _activeNote;
    if (note == null) return 'No hay una nota activa para exportar.';

    try {
      final md = MarkdownConverter.noteToMarkdown(note.title, note.contentJson);
      final name = note.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Exportar nota como Markdown',
        fileName: '$name.md',
        type: FileType.custom,
        allowedExtensions: ['md'],
      );
      if (path == null) return null; // usuario canceló

      await File(path).writeAsString(md, encoding: utf8);
      debugPrint('📄 Nota exportada a: $path');
      return path;
    } catch (e) {
      debugPrint('⚠️ Error exportando nota: $e');
      return 'Error al exportar: $e';
    }
  }

  /// Importa uno o más archivos .md y crea notas en Isar.
  /// Retorna el número de notas importadas o null si se canceló.
  Future<int?> importMarkdownFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Importar archivos Markdown',
        type: FileType.custom,
        allowedExtensions: ['md'],
        allowMultiple: true,
      );
      if (result == null || result.files.isEmpty) return null;

      int count = 0;
      for (final file in result.files) {
        final bytes = file.bytes ?? await File(file.path!).readAsBytes();
        final content = utf8.decode(bytes);
        final (title, body) = MarkdownConverter.parseMarkdown(content);
        final contentJson = MarkdownConverter.plainTextToContentJson(body);

        final note = NoteModel.create(
          title: title,
          contentJson: contentJson,
        );
        await DatabaseService.saveNote(note);
        count++;
      }

      await loadNotes();
      debugPrint('📥 $count nota(s) importada(s)');
      return count;
    } catch (e) {
      debugPrint('⚠️ Error importando notas: $e');
      return -1;
    }
  }
}
