import 'package:isar/isar.dart';

part 'chat_message_model.g.dart';

enum MessageRole { user, assistant, system }

@collection
class ChatMessage {
  Id id = Isar.autoIncrement;

  /// Nullable — mensajes globales si no están vinculados a una nota.
  int? noteId;

  late MessageRole role;
  late String content;
  late String provider;
  String? model;
  late DateTime createdAt;

  /// Segundos de retención configurados al momento de crear el mensaje
  /// (para que RetentionService sepa el plazo aplicable).
  int retentionSeconds = 2592000; // 30 días por defecto

  ChatMessage({
    this.noteId,
    required this.role,
    required this.content,
    required this.provider,
    this.model,
    DateTime? createdAt,
    this.retentionSeconds = 2592000,
  }) : createdAt = createdAt ?? DateTime.now();
}
