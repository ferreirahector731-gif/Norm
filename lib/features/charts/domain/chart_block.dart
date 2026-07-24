/*
 * Copyright (c) 2026 Norm Project. All rights reserved.
 * Licensed under the GNU Affero General Public License v3.0 (AGPLv3).
 */

import 'dart:convert';

import '../../sheets/domain/sheet_block.dart';

enum ChartType { bar, line, pie }

class ChartSeries {
  String name;
  List<double> data;

  ChartSeries({required this.name, required this.data});

  Map<String, dynamic> toJson() => {'name': name, 'data': data};

  factory ChartSeries.fromJson(Map<String, dynamic> json) => ChartSeries(
        name: json['name'] as String? ?? '',
        data: (json['data'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      );
}

class ChartBlock {
  static const String marker = '__norm_type__';
  static const String typeValue = 'chart';

  ChartType chartType;
  String title;
  List<String> labels;
  List<ChartSeries> series;
  int? linkedSheetId;
  int linkedColumn;

  ChartBlock({
    this.chartType = ChartType.bar,
    this.title = 'Telemetría',
    List<String>? labels,
    List<ChartSeries>? series,
    this.linkedSheetId,
    this.linkedColumn = 0,
  })  : labels = labels ?? ['Ene', 'Feb', 'Mar', 'Abr', 'May'],
        series = series ?? [
          ChartSeries(name: 'Serie 1', data: [12, 19, 8, 15, 22]),
        ];

  int get seriesCount => series.length;
  int get pointCount => labels.length;

  void addSeries({String name = ''}) {
    final idx = series.length + 1;
    series.add(ChartSeries(name: name.isEmpty ? 'Serie $idx' : name, data: List.filled(pointCount, 0.0)));
  }

  void removeSeries(int index) {
    if (series.length <= 1) return;
    series.removeAt(index);
  }

  void setChartType(ChartType type) {
    chartType = type;
  }

  void updateLabel(int index, String value) {
    if (index >= 0 && index < labels.length) labels[index] = value;
  }

  void updateData(int seriesIdx, int pointIdx, double value) {
    if (seriesIdx >= 0 && seriesIdx < series.length &&
        pointIdx >= 0 && pointIdx < series[seriesIdx].data.length) {
      series[seriesIdx].data[pointIdx] = value;
    }
  }

  void addLabel({String label = ''}) {
    labels.add(label.isEmpty ? 'P${labels.length + 1}' : label);
    for (final s in series) {
      s.data.add(0.0);
    }
  }

  void removeLabel(int index) {
    if (labels.length <= 1) return;
    labels.removeAt(index);
    for (final s in series) {
      s.data.removeAt(index);
    }
  }

  void loadFromSheet(SheetBlock sheet) {
    if (linkedColumn >= sheet.colCount) return;
    labels.clear();
    for (int r = 0; r < sheet.rowCount; r++) {
      labels.add(sheet.rows[r].isNotEmpty ? sheet.rows[r][0] : 'Fila ${r + 1}');
    }
    if (linkedColumn > 0 && linkedColumn < sheet.colCount) {
      series.clear();
      final colName = sheet.columns[linkedColumn];
      series.add(ChartSeries(
        name: colName,
        data: sheet.rows.map((r) => double.tryParse(r[linkedColumn]) ?? 0.0).toList(),
      ));
    }
  }

  Map<String, dynamic> toJson() => {
        marker: typeValue,
        'chartType': chartType.name,
        'title': title,
        'labels': labels,
        'series': series.map((s) => s.toJson()).toList(),
        'linkedSheetId': linkedSheetId,
        'linkedColumn': linkedColumn,
      };

  factory ChartBlock.fromJson(Map<String, dynamic> json) => ChartBlock(
        chartType: ChartType.values.firstWhere(
          (e) => e.name == json['chartType'],
          orElse: () => ChartType.bar,
        ),
        title: json['title'] as String? ?? 'Telemetría',
        labels: (json['labels'] as List?)?.map((e) => e.toString()).toList() ?? [],
        series: (json['series'] as List?)
                ?.map((e) => ChartSeries.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        linkedSheetId: json['linkedSheetId'] as int?,
        linkedColumn: json['linkedColumn'] as int? ?? 0,
      );

  String encode() => jsonEncode(toJson());

  static bool isChart(String contentJson) {
    try {
      return contentJson.trim().startsWith('{"$marker":"$typeValue"');
    } catch (_) {
      return false;
    }
  }

  factory ChartBlock.decode(String contentJson) {
    final data = jsonDecode(contentJson);
    return ChartBlock.fromJson(data as Map<String, dynamic>);
  }
}
