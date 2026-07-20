import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/notes/domain/note_model.dart';

class DatabaseService {
  static const _storageKey = 'nota_ia_notes_v1';

  static SharedPreferences? _prefs;
  static int _nextId = 1;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final notes = await getAllNotes();
    if (notes.isEmpty) {
      _nextId = 1;
      return;
    }

    final maxId = notes.map((note) => note.id).reduce((a, b) => a > b ? a : b);
    _nextId = maxId + 1;
  }

  static Future<void> saveNote(NoteModel note) async {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('SharedPreferences no está inicializado.');
    }

    note.updatedAt = DateTime.now();
    note.isDirty = true;
    if (note.id == 0) {
      note.id = _nextId++;
      note.createdAt = DateTime.now();
    }

    final notes = await getAllNotes();
    final index = notes.indexWhere((item) => item.id == note.id);
    if (index >= 0) {
      notes[index] = note;
    } else {
      notes.add(note);
    }

    await prefs.setString(_storageKey, jsonEncode(notes.map(_toMap).toList()));
  }

  static Future<List<NoteModel>> getAllNotes() async {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('SharedPreferences no está inicializado.');
    }

    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return [];
    }

    final notes = decoded
        .whereType<Map>()
        .map((item) => _fromMap(Map<String, dynamic>.from(item)))
        .toList();

    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  static Future<void> deleteNote(int id) async {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('SharedPreferences no está inicializado.');
    }

    final notes = await getAllNotes();
    notes.removeWhere((note) => note.id == id);
    await prefs.setString(_storageKey, jsonEncode(notes.map(_toMap).toList()));
  }

  static Future<List<NoteModel>> getDirtyNotes() async {
    final notes = await getAllNotes();
    return notes.where((n) => n.isDirty).toList();
  }

  static Future<void> markSynced(NoteModel note, String remoteId) async {
    note.isDirty = false;
    note.remoteId = remoteId;
    note.lastSyncedAt = DateTime.now();
    await saveNote(note);
  }

  static Future<NoteModel?> getNoteById(int id) async {
    final notes = await getAllNotes();
    return notes.where((n) => n.id == id).firstOrNull;
  }

  static Future<void> upsertRemoteNote({
    required String remoteId,
    required String title,
    required String contentJson,
    required DateTime remoteUpdatedAt,
    String? localRemoteId,
    int? localId,
  }) async {
    final notes = await getAllNotes();

    NoteModel? existing;
    if (localId != null) {
      existing = notes.where((n) => n.id == localId).firstOrNull;
    }
    if (existing == null && remoteId.isNotEmpty) {
      existing = notes.where((n) => n.remoteId == remoteId).firstOrNull;
    }

    if (existing != null) {
      if (remoteUpdatedAt.isAfter(existing.updatedAt)) {
        existing.title = title;
        existing.contentJson = contentJson;
        existing.updatedAt = remoteUpdatedAt;
        existing.isDirty = false;
        existing.remoteId = remoteId;
        existing.lastSyncedAt = DateTime.now();
        await saveNote(existing);
      }
    } else {
      final note = NoteModel.create(
        title: title,
        contentJson: contentJson,
      );
      note.updatedAt = remoteUpdatedAt;
      note.isDirty = false;
      note.remoteId = remoteId;
      note.lastSyncedAt = DateTime.now();
      note.id = _nextId++;
      await saveNote(note);
    }
  }

  static Map<String, dynamic> _toMap(NoteModel note) {
    return {
      'id': note.id,
      'remoteId': note.remoteId,
      'title': note.title,
      'contentJson': note.contentJson,
      'createdAt': note.createdAt.toIso8601String(),
      'updatedAt': note.updatedAt.toIso8601String(),
      'isDirty': note.isDirty,
      'lastSyncedAt': note.lastSyncedAt?.toIso8601String(),
    };
  }

  static NoteModel _fromMap(Map<String, dynamic> map) {
    final note = NoteModel()
      ..id = map['id'] as int
      ..remoteId = map['remoteId'] as String?
      ..title = map['title'] as String? ?? 'Sin título'
      ..contentJson = map['contentJson'] as String? ?? ''
      ..createdAt = DateTime.parse(map['createdAt'] as String)
      ..updatedAt = DateTime.parse(map['updatedAt'] as String)
      ..isDirty = map['isDirty'] as bool? ?? false;
    final syncedStr = map['lastSyncedAt'] as String?;
    if (syncedStr != null) {
      note.lastSyncedAt = DateTime.parse(syncedStr);
    }
    return note;
  }
}
