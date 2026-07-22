import 'package:isar/isar.dart';

part 'block_model.g.dart';

@collection
class BlockModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late String parentId;

  @Index()
  late String type;

  late String content;

  late List<String> properties;

  @Index()
  late int position;

  BlockModel();

  BlockModel.create({
    required this.uuid,
    required this.parentId,
    required this.type,
    required this.content,
    this.properties = const [],
    required this.position,
  });
}
