import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../features/auth/data/auth_service.dart';
import '../../features/notes/domain/note_model.dart';
import '../database/database_service.dart';

class SyncRepository {
  final SupabaseClient _supabase;
  final AuthService _authService;

  SyncRepository(this._supabase, this._authService);

  bool get _canSync =>
      _authService.isCloudEnabled && _authService.isAuthenticated;

  /// Sube una nota local a Supabase (insert o upsert).
  /// Asigna un remoteId UUID si es la primera vez.
  Future<void> upsertNote(NoteModel note) async {
    if (!_canSync) return;

    try {
      final remoteId = note.remoteId ?? const Uuid().v4();
      final userId = _supabase.auth.currentUser!.id;

      await _supabase.from('notes').upsert({
        'id': remoteId,
        'user_id': userId,
        'title': note.title,
        'content_json': note.contentJson,
        'created_at': note.createdAt.toIso8601String(),
        'updated_at': note.updatedAt.toIso8601String(),
      }, onConflict: 'id');

      await DatabaseService.markSynced(note, remoteId);
    } catch (e) {
      debugPrint('⚠️ SyncRepository.upsertNote error: $e');
    }
  }

  /// Sube todas las notas locales con cambios pendientes.
  Future<void> syncDirtyNotes() async {
    if (!_canSync) return;

    try {
      final dirty = await DatabaseService.getDirtyNotes();
      for (final note in dirty) {
        await upsertNote(note);
      }
    } catch (e) {
      debugPrint('⚠️ SyncRepository.syncDirtyNotes error: $e');
    }
  }

  /// Descarga cambios remotos y los aplica localmente (Last-Write-Wins).
  Future<void> fetchRemoteChanges() async {
    if (!_canSync) return;

    try {
      final userId = _supabase.auth.currentUser!.id;
      final remoteNotes = await _supabase
          .from('notes')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      for (final row in remoteNotes) {
        final remoteUpdatedAt = DateTime.parse(row['updated_at'] as String);
        final remoteId = row['id'] as String;

        // Buscar si ya existe localmente
        final existing = await DatabaseService.getNoteByRemoteId(remoteId);
        if (existing != null && existing.updatedAt.isAfter(remoteUpdatedAt)) {
          continue; // local es más reciente, saltar
        }

        await DatabaseService.upsertRemoteNote(
          remoteId: remoteId,
          title: row['title'] as String,
          contentJson: row['content_json'] as String,
          remoteUpdatedAt: remoteUpdatedAt,
          localId: existing?.id,
          localRemoteId: existing?.remoteId,
        );
      }
    } catch (e) {
      debugPrint('⚠️ SyncRepository.fetchRemoteChanges error: $e');
    }
  }
}
