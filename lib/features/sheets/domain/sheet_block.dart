/*
 * Copyright (c) 2026 Norm Project. All rights reserved.
 * Licensed under the GNU Affero General Public License v3.0 (AGPLv3).
 */

import 'dart:convert';

class SheetBlock {
  static const String marker = '__norm_type__';
  static const String typeValue = 'sheet';

  List<String> columns;
  List<List<String>> rows;

  SheetBlock({
    List<String>? columns,
    List<List<String>>? rows,
  })  : columns = columns ?? ['A', 'B', 'C'],
        rows = rows ?? [
          ['', '', ''],
          ['', '', ''],
          ['', '', ''],
        ];

  int get colCount => columns.length;
  int get rowCount => rows.length;

  void addColumn({String name = ''}) {
    columns.add(name.isEmpty ? _nextColumnName() : name);
    for (final row in rows) {
      row.add('');
    }
  }

  void removeColumn(int index) {
    if (columns.length <= 1) return;
    columns.removeAt(index);
    for (final row in rows) {
      row.removeAt(index);
    }
  }

  void renameColumn(int index, String name) {
    if (index >= 0 && index < columns.length) {
      columns[index] = name;
    }
  }

  void addRow() {
    rows.add(List.filled(columns.length, ''));
  }

  void removeRow(int index) {
    if (rows.length <= 1) return;
    rows.removeAt(index);
  }

  void updateCell(int row, int col, String value) {
    if (row >= 0 && row < rows.length && col >= 0 && col < columns.length) {
      rows[row][col] = value;
    }
  }

  String _nextColumnName() {
    int i = columns.length;
    String name = '';
    while (i >= 0) {
      name = String.fromCharCode(65 + (i % 26)) + name;
      i = (i ~/ 26) - 1;
    }
    return name;
  }

  Map<String, dynamic> toJson() => {
        marker: typeValue,
        'columns': columns,
        'rows': rows,
      };

  factory SheetBlock.fromJson(Map<String, dynamic> json) => SheetBlock(
        columns: List<String>.from(json['columns'] ?? []),
        rows: (json['rows'] as List?)
                ?.map((r) => List<String>.from(r as List))
                .toList() ??
            [],
      );

  String encode() => jsonEncode(toJson());

  static bool isSheet(String contentJson) {
    try {
      return contentJson.trim().startsWith('{"$marker":"$typeValue"');
    } catch (_) {
      return false;
    }
  }

  factory SheetBlock.decode(String contentJson) {
    final data = jsonDecode(contentJson);
    return SheetBlock.fromJson(data as Map<String, dynamic>);
  }
}
