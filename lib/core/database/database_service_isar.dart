/*
 * Copyright (c) 2026 Norm Project. All rights reserved.
 * Licensed under the GNU Affero General Public License v3.0 (AGPLv3).
 */

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/ai/domain/chat_message_model.dart';
import '../../features/ai/domain/semantic_context_model.dart';
import '../../features/notes/domain/note_model.dart';
import '../../features/workspace/data/models/block_model.dart';

enum DbStatus { uninitialized, loading, ready, error }

class DbStatusNotifier extends ValueNotifier<DbStatus> {
  DbStatusNotifier() : super(DbStatus.uninitialized);

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setError(String msg) {
    _errorMessage = msg;
    value = DbStatus.error;
  }

  void setReady() {
    _errorMessage = null;
    value = DbStatus.ready;
  }

  void setLoading() {
    _errorMessage = null;
    value = DbStatus.loading;
  }
}

class DatabaseService {
  static Isar? _isar;
  static final DbStatusNotifier statusNotifier = DbStatusNotifier();

  static Isar get isar {
    if (_isar == null) {
      throw StateError(
        'Isar no está inicializado. Llama a DatabaseService.initialize() primero.',
      );
    }
    return _isar!;
  }

  static Future<bool> initialize() async {
    if (_isar != null) return true;

    statusNotifier.setLoading();

    try {
      final dir = await getApplicationDocumentsDirectory();
      _isar = await Isar.open(
        [NoteModelSchema, ChatMessageSchema, BlockModelSchema, SemanticContextSchema],
        directory: dir.path,
        inspector: kDebugMode,
      );
      statusNotifier.setReady();
      return true;
    } catch (e) {
      debugPrint('❌ Isar initialization failed: $e');

      // Fallback: cerrar y recrear la instancia
      try {
        final dir = await getApplicationDocumentsDirectory();
        if (_isar != null) {
          await _isar!.close(deleteFromDisk: true);
        }
        _isar = await Isar.open(
          [NoteModelSchema, ChatMessageSchema, BlockModelSchema, SemanticContextSchema],
          directory: dir.path,
          inspector: kDebugMode,
        );
        statusNotifier.setReady();
        debugPrint('✅ Isar re-initialized successfully after fallback');
        return true;
      } catch (fallbackError) {
        statusNotifier.setError(
          'Error crítico de base de datos local. '
          'Por favor reinicia la app o reinstala.\n$fallbackError',
        );
        debugPrint('❌ Isar fallback also failed: $fallbackError');
        return false;
      }
    }
  }

  static Future<void> saveNote(NoteModel note) async {
    note.updatedAt = DateTime.now();
    note.isDirty = true;
    await isar.writeTxn(() async {
      await isar.noteModels.put(note);
    });
  }

  static Future<List<NoteModel>> getAllNotes() async {
    final notes = await isar.noteModels.where().findAll();
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  static Future<void> deleteNote(int id) async {
    await isar.writeTxn(() async {
      await isar.noteModels.delete(id);
    });
  }

  // --- Sync helpers ---

  /// Retorna todas las notas con cambios locales pendientes.
  static Future<List<NoteModel>> getDirtyNotes() async {
    return isar.noteModels.where().filter().isDirtyEqualTo(true).findAll();
  }

  /// Marca una nota como sincronizada tras subida exitosa a la nube.
  static Future<void> markSynced(NoteModel note, String remoteId) async {
    await isar.writeTxn(() async {
      final local = await isar.noteModels.get(note.id);
      if (local != null) {
        local.remoteId = remoteId;
        local.isDirty = false;
        local.lastSyncedAt = DateTime.now();
        await isar.noteModels.put(local);
      }
    });
  }

  /// Obtiene la nota con la última actualización (para comparación de conflictos).
  static Future<NoteModel?> getNoteById(int id) async {
    return isar.noteModels.get(id);
  }

  /// Busca una nota por su remoteId UUID.
  static Future<NoteModel?> getNoteByRemoteId(String remoteId) async {
    return isar.noteModels
        .where()
        .filter()
        .remoteIdEqualTo(remoteId)
        .findFirst();
  }

  /// Guarda una nota remota en Isar solo si es más reciente (Last-Write-Wins).
  static Future<void> upsertRemoteNote({
    required String remoteId,
    required String title,
    required String contentJson,
    required DateTime remoteUpdatedAt,
    String? localRemoteId,
    int? localId,
  }) async {
    await isar.writeTxn(() async {
      // Buscar si ya existe localmente por remoteId o por id local
      NoteModel? existing;
      if (localId != null) {
        existing = await isar.noteModels.get(localId);
      }
      if (existing == null && remoteId.isNotEmpty) {
        existing = await isar.noteModels
            .where()
            .filter()
            .remoteIdEqualTo(remoteId)
            .findFirst();
      }

      if (existing != null) {
        // Last-Write-Wins: solo actualizar si la nube es más reciente
        if (remoteUpdatedAt.isAfter(existing.updatedAt)) {
          existing.title = title;
          existing.contentJson = contentJson;
          existing.updatedAt = remoteUpdatedAt;
          existing.isDirty = false;
          existing.remoteId = remoteId;
          existing.lastSyncedAt = DateTime.now();
          await isar.noteModels.put(existing);
        }
      } else {
        // No existe localmente, insertar como nueva
        final note = NoteModel.create(
          title: title,
          contentJson: contentJson,
        );
        note.updatedAt = remoteUpdatedAt;
        note.isDirty = false;
        note.remoteId = remoteId;
        note.lastSyncedAt = DateTime.now();
        await isar.noteModels.put(note);
      }
    });
  }

  // ── Blocks ────────────────────────────────────────────

  static Future<void> saveBlock(BlockModel block) async {
    await isar.writeTxn(() async {
      await isar.blockModels.put(block);
    });
  }

  static Future<List<BlockModel>> getBlocksByParent(String parentId) async {
    return isar.blockModels
        .where()
        .filter()
        .parentIdEqualTo(parentId)
        .sortByPosition()
        .findAll();
  }

  static Future<void> deleteBlock(int id) async {
    await isar.writeTxn(() async {
      await isar.blockModels.delete(id);
    });
  }

  // ── Chat Messages ──────────────────────────────────────

  static Future<void> saveChatMessage(ChatMessage msg) async {
    await isar.writeTxn(() async {
      await isar.chatMessages.put(msg);
    });
  }

  /// Retorna mensajes de chat, opcionalmente filtrados por nota.
  static Future<List<ChatMessage>> getChatMessages({
    int? noteId,
    int limit = 50,
  }) async {
    final messages = noteId != null
        ? await isar.chatMessages
            .where()
            .filter()
            .noteIdEqualTo(noteId)
            .sortByCreatedAtDesc()
            .findAll()
        : await isar.chatMessages
            .where()
            .sortByCreatedAtDesc()
            .findAll();
    return messages.take(limit).toList();
  }

  /// Elimina mensajes creados antes de [cutoff].
  static Future<int> deleteOldChatMessages(DateTime cutoff) async {
    return isar.writeTxn<int>(() async {
      final ids = await isar.chatMessages
          .where()
          .filter()
          .createdAtLessThan(cutoff)
          .idProperty()
          .findAll();
      if (ids.isEmpty) return 0;
      return isar.chatMessages.deleteAll(ids);
    });
  }

  // ── Semantic Contexts ─────────────────────────────────

  static Future<void> saveSemanticContext(SemanticContext ctx) async {
    ctx.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.semanticContexts.put(ctx);
    });
  }

  static Future<SemanticContext?> getSemanticContext(String contextKey) async {
    return isar.semanticContexts
        .where()
        .filter()
        .contextKeyEqualTo(contextKey)
        .findFirst();
  }

  static Future<List<SemanticContext>> getAllSemanticContexts() async {
    return isar.semanticContexts.where().findAll();
  }

  static Future<void> deleteSemanticContext(int id) async {
    await isar.writeTxn(() async {
      await isar.semanticContexts.delete(id);
    });
  }

  /// Purga contextos semánticos creados antes de [cutoff].
  /// Si [cutoff] es null, no purga nada.
  static Future<int> purgeOldSemanticContexts(DateTime? cutoff) async {
    if (cutoff == null) return 0;
    return isar.writeTxn<int>(() async {
      final ids = await isar.semanticContexts
          .where()
          .filter()
          .createdAtLessThan(cutoff)
          .idProperty()
          .findAll();
      if (ids.isEmpty) return 0;
      return isar.semanticContexts.deleteAll(ids);
    });
  }
}
