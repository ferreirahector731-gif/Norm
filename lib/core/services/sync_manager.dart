/*
 * Copyright (c) 2026 Norm Project. All rights reserved.
 * Licensed under the GNU Affero General Public License v3.0 (AGPLv3).
 */

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_service.dart';
import '../database/database_service.dart';
import 'sync_repository.dart';

class SyncManager {
  static final SyncManager _instance = SyncManager._();
  factory SyncManager() => _instance;
  SyncManager._();

  bool _isSyncing = false;
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier(false);
  DateTime? lastSyncAt;

  SyncRepository? _repo;

  void init(SupabaseClient supabase, AuthService authService) {
    _repo = SyncRepository(supabase, authService);
  }

  bool get _canSync => _repo != null;

  Future<void> syncPendingNotes() async {
    if (!_canSync) return;
    if (_isSyncing) return;
    _isSyncing = true;
    isSyncingNotifier.value = true;

    try {
      await _repo!.syncDirtyNotes();
      lastSyncAt = DateTime.now();
    } catch (e) {
      debugPrint('⚠️ SyncManager.syncPendingNotes error: $e');
    }

    _isSyncing = false;
    isSyncingNotifier.value = false;
  }

  Future<void> fetchRemoteChanges() async {
    if (!_canSync) return;
    if (_isSyncing) return;
    _isSyncing = true;
    isSyncingNotifier.value = true;

    try {
      await _repo!.fetchRemoteChanges();
      lastSyncAt = DateTime.now();
    } catch (e) {
      debugPrint('⚠️ SyncManager.fetchRemoteChanges error: $e');
    }

    _isSyncing = false;
    isSyncingNotifier.value = false;
  }

  static void scheduleSync() {
    _instance.syncPendingNotes();
  }

  /// Sincronización completa: sube cambios locales y descarga remotos.
  Future<void> fullSync() async {
    if (!_canSync) return;
    if (_isSyncing) return;
    _isSyncing = true;
    isSyncingNotifier.value = true;

    try {
      // Primero subir cambios locales
      await _repo!.syncDirtyNotes();
      // Luego descargar cambios remotos
      await _repo!.fetchRemoteChanges();
      lastSyncAt = DateTime.now();
    } catch (e) {
      debugPrint('⚠️ SyncManager.fullSync error: $e');
    }

    _isSyncing = false;
    isSyncingNotifier.value = false;
  }

  /// Marca todas las notas locales como dirty para forzar sync en próximo login.
  Future<void> markAllLocalNotesDirty() async {
    if (!_canSync) return;
    try {
      final notes = await DatabaseService.getAllNotes();
      for (final note in notes) {
        if (note.remoteId == null) {
          note.isDirty = true;
          await DatabaseService.saveNote(note);
        }
      }
    } catch (e) {
      debugPrint('⚠️ SyncManager.markAllLocalNotesDirty error: $e');
    }
  }
}
