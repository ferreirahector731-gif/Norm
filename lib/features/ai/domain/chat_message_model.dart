import 'package:isar/isar.dart';

part 'chat_message_model.g.dart';

enum MessageRole { user, assistant, system }

@collection
class ChatMessage {
  Id id = Isar.autoIncrement;

  int? noteId;

  @enumerated
  late MessageRole role;
  late String content;
  late String provider;
  String? model;
  late DateTime createdAt;
  int retentionSeconds = 2592000;

  ChatMessage();

  ChatMessage.create({
    this.noteId,
    required this.role,
    required this.content,
    required this.provider,
    this.model,
    this.retentionSeconds = 2592000,
  }) : createdAt = DateTime.now();
}
