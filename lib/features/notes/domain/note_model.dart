import 'package:isar/isar.dart';

part 'note_model.g.dart';

@collection
class NoteModel {
  Id id = Isar.autoIncrement;

  late String title;

  late String contentJson;

  late DateTime createdAt;
  late DateTime updatedAt;

  /// Marca si hay cambios locales pendientes de subir a la nube.
  bool isDirty = false;

  /// UUID remoto para sincronización (nullable hasta el primer sync).
  String? remoteId;

  /// Última vez que se sincronizó con la nube.
  DateTime? lastSyncedAt;

  @Deprecated('Usar isDirty en su lugar')
  bool isSynced = false;

  NoteModel();

  NoteModel.create({
    required this.title,
    required this.contentJson,
  })  : createdAt = DateTime.now(),
        updatedAt = DateTime.now();
}

