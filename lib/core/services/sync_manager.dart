import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/database_service.dart';

class SyncManager {
  static final SyncManager _instance = SyncManager._();
  factory SyncManager() => _instance;
  SyncManager._();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isSyncing = false;
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier(false);
  final Connectivity _connectivity = Connectivity();

  /// Fecha de la última sincronización exitosa.
  DateTime? lastSyncAt;

  /// Inicia la escucha de cambios de conectividad.
  void startListening() {
    _connectivitySub?.cancel();
    _connectivitySub = _connectivity.onConnectivityChanged.listen((result) {
      if (result.any((r) => r != ConnectivityResult.none)) {
        // Conexión recuperada: sincronizar en segundo plano
        syncPendingNotes();
        fetchRemoteChanges();
      }
    });
  }

  void stopListening() {
    _connectivitySub?.cancel();
  }

  /// Sube todas las notas locales con isDirty == true a Supabase.
  /// Usa upsert con remoteId para evitar duplicados.
  Future<void> syncPendingNotes() async {
    if (_isSyncing) return;
    _isSyncing = true;
    isSyncingNotifier.value = true;

    try {
      final dirtyNotes = await DatabaseService.getDirtyNotes();
      if (dirtyNotes.isEmpty) return;

      for (final note in dirtyNotes) {
        try {
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId == null) return;

          final response = await Supabase.instance.client.from('notes').upsert({
            if (note.remoteId != null) 'id': note.remoteId,
            'user_id': userId,
            'title': note.title,
            'content_json': note.contentJson,
            'updated_at': note.updatedAt.toIso8601String(),
            'created_at': note.createdAt.toIso8601String(),
          }, onConflict: 'id').select('id').single();

          final remoteId = response['id'] as String;
          await DatabaseService.markSynced(note, remoteId);
        } catch (e) {
          // Error silencioso: reintentar en el próximo ciclo
        }
      }
    } finally {
      _isSyncing = false;
      isSyncingNotifier.value = false;
      lastSyncAt = DateTime.now();
    }
  }

  /// Trae cambios remotos desde Supabase y los aplica localmente
  /// usando Last-Write-Wins si la versión de la nube es más reciente.
  Future<void> fetchRemoteChanges() async {
    try {
      // Obtener notas modificadas en la nube desde la última sincronización
      final query = Supabase.instance.client
          .from('notes')
          .select('id, title, content_json, updated_at, created_at');

      if (lastSyncAt != null) {
        query.gt('updated_at', lastSyncAt!.toIso8601String());
      }

      final remoteNotes = await query;
      if (remoteNotes.isEmpty) return;

      for (final remote in remoteNotes) {
        final remoteId = remote['id'] as String;
        final title = remote['title'] as String? ?? '';
        final contentJson = remote['content_json'] as String? ?? '';
        final updatedAtStr = remote['updated_at'] as String?;
        if (updatedAtStr == null) continue;

        final remoteUpdatedAt = DateTime.parse(updatedAtStr);

        await DatabaseService.upsertRemoteNote(
          remoteId: remoteId,
          title: title,
          contentJson: contentJson,
          remoteUpdatedAt: remoteUpdatedAt,
        );
      }
    } catch (_) {
      // Error silencioso: reintentar en el próximo ciclo
    }
  }

  /// Dispara sincronización asíncrona no bloqueante después de un guardado local.
  static void scheduleSync() {
    SyncManager().syncPendingNotes();
  }
}
