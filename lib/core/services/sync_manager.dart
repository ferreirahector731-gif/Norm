import 'dart:async';
import 'package:flutter/foundation.dart';

/// Gestor de sincronización en la nube.
///
/// Actualmente desactivado tras la migración de Supabase a Firebase.
/// La sincronización remota se reimplementará en una versión futura.
class SyncManager {
  static final SyncManager _instance = SyncManager._();
  factory SyncManager() => _instance;
  SyncManager._();

  bool _isSyncing = false;
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier(false);

  /// Fecha de la última sincronización exitosa.
  DateTime? lastSyncAt;

  void startListening() {}

  void stopListening() {}

  Future<void> syncPendingNotes() async {}

  Future<void> fetchRemoteChanges() async {}

  static void scheduleSync() {}
}
