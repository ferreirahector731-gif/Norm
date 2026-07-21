import 'package:flutter/material.dart';

class TableWidget extends StatefulWidget {
  final int initialRows;
  final int initialCols;

  const TableWidget({super.key, this.initialRows = 3, this.initialCols = 3});

  @override
  State<TableWidget> createState() => _TableWidgetState();
}

class _TableWidgetState extends State<TableWidget> {
  late List<List<TextEditingController>> _cells;

  @override
  void initState() {
    super.initState();
    _cells = List.generate(
      widget.initialRows,
      (_) => List.generate(widget.initialCols, (_) => TextEditingController()),
    );
  }

  void _addRow() {
    setState(() => _cells.add(
        List.generate(_cells[0].length, (_) => TextEditingController())));
  }

  void _addColumn() {
    setState(
        () => _cells.forEach((row) => row.add(TextEditingController())));
  }

  void _removeRow(int index) {
    if (_cells.length > 1) {
      setState(() {
        _cells[index].forEach((c) => c.dispose());
        _cells.removeAt(index);
      });
    }
  }

  void _removeColumn(int index) {
    if (_cells[0].length > 1) {
      setState(() => _cells.forEach((row) {
            row[index].dispose();
            row.removeAt(index);
          }));
    }
  }

  @override
  void dispose() {
    for (final row in _cells) {
      for (final c in row) c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: List.generate(_cells[0].length, (col) {
              return DataColumn(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.table_chart_outlined, size: 14),
                    if (_cells[0].length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 16),
                        onPressed: () => _removeColumn(col),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              );
            }),
            rows: List.generate(_cells.length, (row) {
              return DataRow(cells: List.generate(_cells[row].length, (col) {
                return DataCell(
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _cells[row][col],
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.all(8),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  onTap: () => _cells[row][col].selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _cells[row][col].text.length,
                  ),
                );
              }));
            }),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.table_rows, size: 18),
              label: const Text('Fila'),
              onPressed: _addRow,
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.view_column, size: 18),
              label: const Text('Columna'),
              onPressed: _addColumn,
            ),
          ],
        ),
      ],
    );
  }
}
