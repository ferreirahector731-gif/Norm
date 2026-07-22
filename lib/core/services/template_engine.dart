import 'dart:convert';

import 'package:isar/isar.dart';

import '../../features/workspace/data/models/block_model.dart';

class TemplateEngine {
  final Isar isar;

  TemplateEngine(this.isar);

  Future<void> instantiateTemplate(
    String templateRawJson,
    String targetParentId,
  ) async {
    final decoded = jsonDecode(templateRawJson);

    if (decoded is! List) {
      throw ArgumentError('La plantilla debe ser un array de bloques JSON.');
    }

    final blocksJson = decoded as List<dynamic>;

    await isar.writeTxn(() async {
      for (final item in blocksJson) {
        if (item is! Map<String, dynamic>) continue;

        final block = BlockModel.create(
          uuid: DateTime.now().microsecondsSinceEpoch.toString(),
          parentId: targetParentId,
          type: item['type'] as String? ?? 'text',
          content: item['content'] as String? ?? '',
          properties: _parseProperties(item['properties']),
          position: item['position'] as int? ?? 0,
        );

        await isar.blockModels.put(block);
      }
    });
  }

  List<String> _parseProperties(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }
}
