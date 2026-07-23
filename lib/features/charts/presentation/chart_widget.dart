import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../domain/chart_block.dart';
import '../../../../core/widgets/concentric_card.dart';
import '../../notes/domain/note_model.dart';
import '../../sheets/domain/sheet_block.dart';

class ChartWidget extends StatefulWidget {
  final ChartBlock chart;
  final ValueChanged<ChartBlock> onChanged;
  final List<NoteModel> allNotes;
  final void Function(String message)? onLinkSheet;

  const ChartWidget({
    super.key,
    required this.chart,
    required this.onChanged,
    this.allNotes = const [],
    this.onLinkSheet,
  });

  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> {
  late ChartBlock _chart;
  final List<TextEditingController> _labelControllers = [];
  final List<List<TextEditingController>> _dataControllers = [];
  final TextEditingController _titleController = TextEditingController();
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _chart = widget.chart;
    _titleController.text = _chart.title;
    _rebuildControllers();
  }

  @override
  void didUpdateWidget(ChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chart != widget.chart) {
      _disposeControllers();
      _chart = widget.chart;
      _titleController.text = _chart.title;
      _rebuildControllers();
    }
  }

  void _disposeControllers() {
    _titleController.dispose();
    for (final c in _labelControllers) c.dispose();
    for (final row in _dataControllers) {
      for (final c in row) c.dispose();
    }
    _labelControllers.clear();
    _dataControllers.clear();
  }

  void _rebuildControllers() {
    _labelControllers.clear();
    _dataControllers.clear();
    for (int i = 0; i < _chart.pointCount; i++) {
      _labelControllers.add(TextEditingController(text: _chart.labels[i]));
    }
    for (int s = 0; s < _chart.seriesCount; s++) {
      _dataControllers.add([]);
      for (int p = 0; p < _chart.pointCount; p++) {
        _dataControllers[s].add(TextEditingController(
          text: _chart.series[s].data[p].toString(),
        ));
      }
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _notifyChanged() {
    _chart.title = _titleController.text;
    widget.onChanged(_chart);
  }

  void _addPoint() {
    setState(() {
      _chart.addLabel();
      _labelControllers.add(TextEditingController());
      for (int s = 0; s < _chart.seriesCount; s++) {
        _dataControllers[s].add(TextEditingController(text: '0'));
      }
    });
    _notifyChanged();
  }

  void _removePoint(int index) {
    if (_chart.pointCount <= 1) return;
    setState(() {
      _chart.removeLabel(index);
      _labelControllers[index].dispose();
      _labelControllers.removeAt(index);
      for (int s = 0; s < _dataControllers.length; s++) {
        _dataControllers[s][index].dispose();
        _dataControllers[s].removeAt(index);
      }
    });
    _notifyChanged();
  }

  void _addSeries() {
    setState(() {
      _chart.addSeries();
      final s = _chart.seriesCount - 1;
      _dataControllers.add([]);
      for (int p = 0; p < _chart.pointCount; p++) {
        _dataControllers[s].add(TextEditingController(text: '0'));
      }
    });
    _notifyChanged();
  }

  void _removeSeries(int index) {
    if (_chart.seriesCount <= 1) return;
    setState(() {
      _chart.removeSeries(index);
      for (final c in _dataControllers[index]) c.dispose();
      _dataControllers.removeAt(index);
    });
    _notifyChanged();
  }

  void _linkToSheet() {
    final sheets = widget.allNotes
        .where((n) => SheetBlock.isSheet(n.contentJson))
        .toList();

    if (sheets.isEmpty) {
      widget.onLinkSheet?.call('No hay hojas de datos. Crea una desde SHEET.');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vincular a Hoja de Datos'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sheets.length,
            itemBuilder: (_, i) {
              final sheet = sheets[i];
              final data = SheetBlock.decode(sheet.contentJson);
              return ListTile(
                leading: const Icon(Icons.table_chart_outlined, color: Color(0xFF38BDF8)),
                title: Text(sheet.title, style: const TextStyle(fontSize: 14)),
                subtitle: Text('${data.colCount} col × ${data.rowCount} fil',
                    style: const TextStyle(fontSize: 11)),
                onTap: () {
                  _chart.linkedSheetId = sheet.id;
                  Navigator.of(ctx).pop();
                  _showColumnPicker(data);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
        ],
      ),
    );
  }

  void _showColumnPicker(SheetBlock sheet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seleccionar Columna'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sheet.colCount,
            itemBuilder: (_, i) {
              final colName = sheet.columns[i];
              final isNumeric = sheet.rows.any((r) => double.tryParse(r[i]) != null);
              return ListTile(
                leading: Icon(
                  isNumeric ? Icons.bar_chart : Icons.text_fields,
                  color: const Color(0xFFA78BFA),
                ),
                title: Text(colName, style: const TextStyle(fontSize: 14)),
                subtitle: Text(isNumeric ? 'Datos numéricos' : 'Texto',
                    style: const TextStyle(fontSize: 11)),
                onTap: () {
                  _chart.linkedColumn = i;
                  _chart.loadFromSheet(sheet);
                  _disposeControllers();
                  _rebuildControllers();
                  Navigator.of(ctx).pop();
                  setState(() {});
                  _notifyChanged();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ConcentricCard(
      level: ConcentricLevel.outer,
      padding: const EdgeInsets.all(0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildTypeSelector(context),
          _buildChart(context),
          _buildDataTable(context),
          _buildFooter(context),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(Icons.bar_chart_outlined, size: 16, color: const Color(0xFFA78BFA)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _titleController,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Título del gráfico',
                hintStyle: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant.withOpacity(0.3)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => _notifyChanged(),
            ),
          ),
          if (_chart.linkedSheetId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'VINCULADO',
                style: TextStyle(fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SegmentedButton<ChartType>(
        segments: const [
          ButtonSegment(value: ChartType.bar, icon: Icon(Icons.bar_chart, size: 16), label: Text('Barras', style: TextStyle(fontSize: 10))),
          ButtonSegment(value: ChartType.line, icon: Icon(Icons.show_chart, size: 16), label: Text('Líneas', style: TextStyle(fontSize: 10))),
          ButtonSegment(value: ChartType.pie, icon: Icon(Icons.pie_chart, size: 16), label: Text('Pastel', style: TextStyle(fontSize: 10))),
        ],
        selected: {_chart.chartType},
        onSelectionChanged: (selected) {
          setState(() => _chart.setChartType(selected.first));
          _notifyChanged();
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return scheme.primary.withOpacity(0.15);
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return scheme.primary;
            return scheme.onSurfaceVariant;
          }),
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = [
      const Color(0xFFA78BFA),
      const Color(0xFF38BDF8),
      const Color(0xFF34D399),
      const Color(0xFFFBBF24),
      const Color(0xFFFB7185),
    ];

    return ConcentricCard(
      level: ConcentricLevel.inner,
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        height: 220,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _chart.chartType == ChartType.pie
              ? _buildPieChart(context, colors)
              : _buildAxisChart(context, colors),
        ),
      ),
    );
  }

  Widget _buildAxisChart(BuildContext context, List<Color> colors) {
    final scheme = Theme.of(context).colorScheme;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: scheme.outline.withOpacity(0.08),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= _chart.pointCount) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _chart.labels[idx],
                    style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant.withOpacity(0.5)),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant.withOpacity(0.4)),
              ),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: List.generate(_chart.seriesCount, (s) {
          final color = colors[s % colors.length];
          final data = _chart.series[s].data;
          return LineChartBarData(
            spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i])),
            isCurved: _chart.chartType == ChartType.line,
            color: color,
            barWidth: _chart.chartType == ChartType.line ? 2.5 : 0,
            belowBarData: BarAreaData(
              show: _chart.chartType == ChartType.bar,
              color: color.withOpacity(0.08),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 2.5,
                color: color,
                strokeWidth: 0,
              ),
            ),
          );
        }),
      ),
      duration: const Duration(milliseconds: 200),
    );
  }

  Widget _buildPieChart(BuildContext context, List<Color> colors) {
    final scheme = Theme.of(context).colorScheme;

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (event, response) {
            setState(() => _touchedIndex = response?.touchedSection?.touchedSectionIndex);
          },
        ),
        sections: List.generate(_chart.pointCount, (i) {
          final value = _chart.series.isNotEmpty && i < _chart.series[0].data.length
              ? _chart.series[0].data[i]
              : 0.0;
          final isTouched = i == _touchedIndex;
          return PieChartSectionData(
            color: colors[i % colors.length],
            value: value > 0 ? value : 1,
            title: isTouched ? '${value.toInt()}' : _chart.labels[i],
            radius: isTouched ? 55 : 45,
            titleStyle: TextStyle(
              fontSize: isTouched ? 11 : 9,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }),
        sectionsSpace: 2,
        centerSpaceRadius: 32,
      ),
      duration: const Duration(milliseconds: 200),
    );
  }

  Widget _buildDataTable(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Datos', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          ConcentricCard(
            level: ConcentricLevel.innerMost,
            padding: const EdgeInsets.all(0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDataHeaderRow(context),
                    ...List.generate(_chart.seriesCount, (s) => _buildDataSeriesRow(context, s)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataHeaderRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: scheme.primary.withOpacity(0.06),
      child: Row(
        children: [
          _dataCornerCell(context),
          ...List.generate(_chart.pointCount, (i) => _dataLabelCell(context, i)),
          _dataAddCell(context),
        ],
      ),
    );
  }

  Widget _dataCornerCell(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 80, height: 30,
      decoration: BoxDecoration(border: Border(right: BorderSide(color: scheme.outline.withOpacity(0.1)))),
      alignment: Alignment.center,
      child: Text('Serie', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
    );
  }

  Widget _dataLabelCell(BuildContext context, int idx) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 60, height: 30,
      decoration: BoxDecoration(border: Border(right: BorderSide(color: scheme.outline.withOpacity(0.1)))),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            child: TextField(
              controller: _labelControllers[idx],
              style: TextStyle(fontSize: 10, color: scheme.onSurface),
              decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
              textAlign: TextAlign.center,
              onChanged: (v) {
                _chart.updateLabel(idx, v);
                _notifyChanged();
              },
            ),
          ),
          InkWell(
            onTap: () => _removePoint(idx),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.close, size: 10, color: scheme.onSurfaceVariant.withOpacity(0.3)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataAddCell(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 28, height: 30,
      alignment: Alignment.center,
      child: InkWell(
        onTap: _addPoint,
        child: Icon(Icons.add, size: 14, color: const Color(0xFFA78BFA)),
      ),
    );
  }

  Widget _buildDataSeriesRow(BuildContext context, int seriesIdx) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: scheme.outline.withOpacity(0.06)))),
      child: Row(
        children: [
          _dataSeriesNameCell(context, seriesIdx),
          ...List.generate(_chart.pointCount, (p) => _dataValueCell(context, seriesIdx, p)),
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  Widget _dataSeriesNameCell(BuildContext context, int seriesIdx) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 80, height: 28,
      decoration: BoxDecoration(border: Border(right: BorderSide(color: scheme.outline.withOpacity(0.1)))),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _chart.series[seriesIdx].name,
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: () => _removeSeries(seriesIdx),
            child: Icon(Icons.close, size: 10, color: scheme.onSurfaceVariant.withOpacity(0.2)),
          ),
        ],
      ),
    );
  }

  Widget _dataValueCell(BuildContext context, int seriesIdx, int pointIdx) {
    final scheme = Theme.of(context).colorScheme;
    final controller = _dataControllers[seriesIdx][pointIdx];

    return Container(
      width: 60, height: 28,
      decoration: BoxDecoration(border: Border(right: BorderSide(color: scheme.outline.withOpacity(0.1)))),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: 10, color: scheme.onSurface),
        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        onChanged: (v) {
          _chart.updateData(seriesIdx, pointIdx, double.tryParse(v) ?? 0.0);
          setState(() {});
          _notifyChanged();
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _addSeries,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_chart_outlined, size: 14, color: const Color(0xFFA78BFA)),
                    const SizedBox(width: 4),
                    Text('Serie', style: TextStyle(fontSize: 11, color: const Color(0xFFA78BFA))),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _linkToSheet,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link, size: 14, color: const Color(0xFF38BDF8)),
                    const SizedBox(width: 4),
                    Text('Vincular SHEET', style: TextStyle(fontSize: 11, color: const Color(0xFF38BDF8))),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          if (_chart.linkedSheetId != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    _chart.linkedSheetId = null;
                    _chart.linkedColumn = 0;
                  });
                  _notifyChanged();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link_off, size: 14, color: scheme.onSurfaceVariant.withOpacity(0.4)),
                      const SizedBox(width: 4),
                      Text('Desvincular', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant.withOpacity(0.4))),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
