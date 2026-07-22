import 'package:flutter/foundation.dart';

import '../../domain/note_model.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/services/sync_manager.dart';

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
}
