import 'package:flutter/material.dart';

import '../domain/task_block.dart';
import '../../../../core/widgets/concentric_card.dart';

class TaskWidget extends StatefulWidget {
  final TaskBlock block;
  final ValueChanged<TaskBlock> onChanged;

  const TaskWidget({
    super.key,
    required this.block,
    required this.onChanged,
  });

  @override
  State<TaskWidget> createState() => _TaskWidgetState();
}

class _TaskWidgetState extends State<TaskWidget> {
  late TaskBlock _block;
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  TaskFilter _filter = TaskFilter.all;

  @override
  void initState() {
    super.initState();
    _block = widget.block;
  }

  @override
  void didUpdateWidget(TaskWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block != widget.block) {
      _block = widget.block;
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _notifyChanged() {
    widget.onChanged(_block);
  }

  void _addTask() {
    final text = _inputController.text;
    if (text.trim().isEmpty) return;

    if (text.contains('@') || text.contains('#')) {
      _block.addFromNlp(text);
    } else {
      _block.addTask(text);
    }
    _inputController.clear();
    _notifyChanged();
    setState(() {});
  }

  void _toggleTask(String id) {
    _block.toggleTask(id);
    _notifyChanged();
    setState(() {});
  }

  void _removeTask(String id) {
    _block.removeTask(id);
    _notifyChanged();
    setState(() {});
  }

  void _clearCompleted() {
    _block.tasks.removeWhere((t) => t.isCompleted);
    _notifyChanged();
    setState(() {});
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return const Color(0xFF34D399);
      case TaskPriority.medium:
        return const Color(0xFF38BDF8);
      case TaskPriority.high:
        return const Color(0xFFFBBF24);
      case TaskPriority.urgent:
        return const Color(0xFFFB7185);
    }
  }

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return 'Baja';
      case TaskPriority.medium:
        return 'Media';
      case TaskPriority.high:
        return 'Alta';
      case TaskPriority.urgent:
        return 'Urgente';
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = date.difference(today).inDays;

    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    if (diff == -1) return 'Ayer';
    if (diff > 0 && diff <= 7) return 'En $diff días';
    if (diff < 0 && diff >= -7) return 'Hace ${-diff} días';
    return '${dt.day}/${dt.month}/${dt.year}';
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
          _buildStatsRow(context),
          _buildInputField(context),
          const SizedBox(height: 8),
          _buildFilterTabs(context),
          _buildTaskList(context),
          if (_block.completedCount > 0) _buildFooter(context),
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
          Icon(Icons.checklist_rtl, size: 16, color: const Color(0xFFFBBF24)),
          const SizedBox(width: 8),
          Text(
            'Tareas',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface),
          ),
          const Spacer(),
          Text(
            '${_block.activeCount} pendientes',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statChip(context, '${_block.totalCount}', 'Total', scheme.primary),
          const SizedBox(width: 8),
          _statChip(context, '${_block.activeCount}', 'Activas', const Color(0xFF38BDF8)),
          const SizedBox(width: 8),
          _statChip(context, '${_block.completedCount}', 'Hechas', const Color(0xFF34D399)),
          if (_block.overdueCount > 0) ...[
            const SizedBox(width: 8),
            _statChip(context, '${_block.overdueCount}', 'Vencidas', const Color(0xFFFB7185)),
          ],
        ],
      ),
    );
  }

  Widget _statChip(BuildContext context, String count, String label, Color color) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant.withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _buildInputField(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ConcentricCard(
        level: ConcentricLevel.innerMost,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                focusNode: _inputFocus,
                style: TextStyle(fontSize: 13, color: scheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Añadir tarea...  (ej: "Comprar leche mañana @high #personal")',
                  hintStyle: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant.withOpacity(0.35)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => _addTask(),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _addTask,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.add_rounded, size: 18, color: const Color(0xFFFBBF24)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final filters = [
      (TaskFilter.all, 'Todas'),
      (TaskFilter.active, 'Activas'),
      (TaskFilter.done, 'Hechas'),
      if (_block.overdueCount > 0) (TaskFilter.overdue, 'Vencidas'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final (filter, label) = f;
            final isSelected = _filter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(() => _filter = filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? scheme.primary.withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? scheme.primary.withOpacity(0.3) : scheme.outlineVariant.withOpacity(0.15),
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTaskList(BuildContext context) {
    final filtered = _block.filtered(_filter);

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            _filter == TaskFilter.all ? 'No hay tareas. Escribe arriba para añadir.' : 'Sin resultados.',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4)),
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: filtered.length,
      onReorder: (oldIdx, newIdx) {
        final realOld = _block.tasks.indexOf(filtered[oldIdx]);
        final realNew = _block.tasks.indexOf(filtered[newIdx > oldIdx ? newIdx - 1 : newIdx]);
        if (realOld >= 0 && realNew >= 0) {
          _block.reorder(realOld, realNew);
          _notifyChanged();
          setState(() {});
        }
      },
      proxyDecorator: (child, index, animation) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) => Material(
          color: Colors.transparent,
          elevation: 4,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
        child: child,
      ),
      itemBuilder: (context, index) {
        final task = filtered[index];
        return _buildTaskItem(context, task);
      },
    );
  }

  Widget _buildTaskItem(BuildContext context, TaskItem task) {
    final scheme = Theme.of(context).colorScheme;
    final priorityColor = _priorityColor(task.priority);

    return Container(
      key: ValueKey(task.id),
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ConcentricCard(
        level: ConcentricLevel.innerMost,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _toggleTask(task.id),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: task.isCompleted ? priorityColor.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: task.isCompleted ? priorityColor : scheme.outline.withOpacity(0.3),
                    width: task.isCompleted ? 0 : 1.5,
                  ),
                ),
                child: task.isCompleted
                    ? Icon(Icons.check, size: 14, color: priorityColor)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 13,
                      color: task.isCompleted
                          ? scheme.onSurfaceVariant.withOpacity(0.4)
                          : scheme.onSurface,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          _priorityLabel(task.priority),
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: priorityColor),
                        ),
                      ),
                      if (task.category != null) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF818CF8).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '#${task.category}',
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF818CF8)),
                          ),
                        ),
                      ],
                      if (task.dueDate != null) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: task.isOverdue
                                ? const Color(0xFFFB7185).withOpacity(0.12)
                                : scheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            _formatDate(task.dueDate!),
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: task.isOverdue
                                  ? const Color(0xFFFB7185)
                                  : scheme.onSurfaceVariant.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _removeTask(task.id),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 14, color: scheme.onSurfaceVariant.withOpacity(0.25)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _clearCompleted,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cleaning_services_outlined, size: 14, color: scheme.onSurfaceVariant.withOpacity(0.4)),
                    const SizedBox(width: 4),
                    Text(
                      'Limpiar completadas (${_block.completedCount})',
                      style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant.withOpacity(0.4)),
                    ),
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
