import 'package:isar/isar.dart';

part 'semantic_context_model.g.dart';

@collection
class SemanticContext {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String contextKey;

  late String content;

  @Index()
  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;

  SemanticContext();

  SemanticContext.create({
    required this.contextKey,
    required this.content,
  })  : createdAt = DateTime.now(),
        updatedAt = DateTime.now();
}
