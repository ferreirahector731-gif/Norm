import 'package:flutter/material.dart';

import '../domain/sheet_block.dart';
import '../../../../core/widgets/concentric_card.dart';

class SheetWidget extends StatefulWidget {
  final SheetBlock sheet;
  final ValueChanged<SheetBlock> onChanged;

  const SheetWidget({
    super.key,
    required this.sheet,
    required this.onChanged,
  });

  @override
  State<SheetWidget> createState() => _SheetWidgetState();
}

class _SheetWidgetState extends State<SheetWidget> {
  late SheetBlock _sheet;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _sheet = widget.sheet;
    _initControllers();
  }

  @override
  void didUpdateWidget(SheetWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sheet != widget.sheet) {
      _disposeControllers();
      _sheet = widget.sheet;
      _initControllers();
    }
  }

  void _initControllers() {
    for (int r = 0; r < _sheet.rowCount; r++) {
      for (int c = 0; c < _sheet.colCount; c++) {
        _controllers['$r:$c'] = TextEditingController(text: _sheet.rows[r][c]);
      }
    }
  }

  void _disposeControllers() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _notifyChanged() {
    widget.onChanged(_sheet);
  }

  void _addRow() {
    setState(() {
      _sheet.addRow();
      final r = _sheet.rowCount - 1;
      for (int c = 0; c < _sheet.colCount; c++) {
        _controllers['$r:$c'] = TextEditingController();
      }
    });
    _notifyChanged();
  }

  void _addColumn() {
    setState(() {
      _sheet.addColumn();
      final c = _sheet.colCount - 1;
      for (int r = 0; r < _sheet.rowCount; r++) {
        _controllers['$r:$c'] = TextEditingController();
      }
    });
    _notifyChanged();
  }

  void _removeRow(int index) {
    if (_sheet.rowCount <= 1) return;
    setState(() {
      for (int c = 0; c < _sheet.colCount; c++) {
        _controllers.remove('$index:$c');
      }
      _sheet.removeRow(index);
      _shiftControllersAfterRowRemoval(index);
    });
    _notifyChanged();
  }

  void _shiftControllersAfterRowRemoval(int removedIndex) {
    final newControllers = <String, TextEditingController>{};
    for (int r = 0; r < _sheet.rowCount; r++) {
      for (int c = 0; c < _sheet.colCount; c++) {
        final oldKey = r >= removedIndex ? '${r + 1}:$c' : '$r:$c';
        final ctrl = _controllers[oldKey];
        if (ctrl != null) {
          newControllers['$r:$c'] = ctrl;
        }
      }
    }
    _controllers.clear();
    _controllers.addAll(newControllers);
  }

  void _removeColumn(int index) {
    if (_sheet.colCount <= 1) return;
    setState(() {
      for (int r = 0; r < _sheet.rowCount; r++) {
        _controllers.remove('$r:$index');
      }
      _sheet.removeColumn(index);
      _shiftControllersAfterColumnRemoval(index);
    });
    _notifyChanged();
  }

  void _shiftControllersAfterColumnRemoval(int removedIndex) {
    final newControllers = <String, TextEditingController>{};
    for (int r = 0; r < _sheet.rowCount; r++) {
      for (int c = 0; c < _sheet.colCount; c++) {
        final oldKey = c >= removedIndex ? '$r:${c + 1}' : '$r:$c';
        final ctrl = _controllers[oldKey];
        if (ctrl != null) {
          newControllers['$r:$c'] = ctrl;
        }
      }
    }
    _controllers.clear();
    _controllers.addAll(newControllers);
  }

  void _renameColumn(int index, String name) {
    _sheet.renameColumn(index, name);
    _notifyChanged();
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
          _buildToolbar(context),
          _buildTable(context),
          const SizedBox(height: 8),
          _buildAddButtons(context),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Icon(Icons.table_chart_outlined, size: 16, color: const Color(0xFF38BDF8)),
          const SizedBox(width: 8),
          Text(
            'Hoja de Datos',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const Spacer(),
          Text(
            '${_sheet.colCount} × ${_sheet.rowCount}',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: scheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ConcentricCard(
      level: ConcentricLevel.inner,
      padding: const EdgeInsets.all(0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeaderRow(context),
                ...List.generate(_sheet.rowCount, (r) => _buildRow(context, r)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.08),
        border: Border(
          bottom: BorderSide(color: scheme.outline.withOpacity(0.15)),
        ),
      ),
      child: Row(
        children: [
          _cornerCell(context),
          ...List.generate(_sheet.colCount, (c) => _buildHeaderCell(context, c)),
        ],
      ),
    );
  }

  Widget _cornerCell(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 44,
      height: 36,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: scheme.outline.withOpacity(0.1)),
          bottom: BorderSide(color: scheme.outline.withOpacity(0.1)),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.table_chart_outlined, size: 12, color: scheme.onSurfaceVariant.withOpacity(0.3)),
    );
  }

  Widget _buildHeaderCell(BuildContext context, int col) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 120,
      height: 36,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: scheme.outline.withOpacity(0.1)),
          bottom: BorderSide(color: scheme.outline.withOpacity(0.1)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showRenameDialog(context, col),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _sheet.columns[col],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () => _removeColumn(col),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(Icons.close, size: 12, color: scheme.onSurfaceVariant.withOpacity(0.4)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, int row) {
    return Row(
      children: [
        _buildRowHeader(context, row),
        ...List.generate(_sheet.colCount, (c) => _buildCell(context, row, c)),
      ],
    );
  }

  Widget _buildRowHeader(BuildContext context, int row) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 44,
      height: 36,
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.04),
        border: Border(
          right: BorderSide(color: scheme.outline.withOpacity(0.1)),
          bottom: BorderSide(color: scheme.outline.withOpacity(0.1)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _removeRow(row),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${row + 1}',
                style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant.withOpacity(0.5)),
              ),
              const SizedBox(width: 2),
              Icon(Icons.close, size: 10, color: scheme.onSurfaceVariant.withOpacity(0.2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(BuildContext context, int row, int col) {
    final scheme = Theme.of(context).colorScheme;
    final controller = _controllers.putIfAbsent('$row:$col', () => TextEditingController());

    return Container(
      width: 120,
      height: 36,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: scheme.outline.withOpacity(0.08)),
          bottom: BorderSide(color: scheme.outline.withOpacity(0.08)),
        ),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: 12, color: scheme.onSurface),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          isDense: true,
        ),
        onChanged: (value) {
          _sheet.updateCell(row, col, value);
          _notifyChanged();
        },
      ),
    );
  }

  Widget _buildAddButtons(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _addRow,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.table_rows_outlined, size: 14, color: const Color(0xFF38BDF8)),
                    const SizedBox(width: 4),
                    Text('Fila', style: TextStyle(fontSize: 11, color: const Color(0xFF38BDF8))),
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
              onTap: _addColumn,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.view_column_outlined, size: 14, color: const Color(0xFF38BDF8)),
                    const SizedBox(width: 4),
                    Text('Columna', style: TextStyle(fontSize: 11, color: const Color(0xFF38BDF8))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, int col) {
    final controller = TextEditingController(text: _sheet.columns[col]);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renombrar columna'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nombre de columna',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _renameColumn(col, controller.text);
              controller.dispose();
              Navigator.of(ctx).pop();
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}
