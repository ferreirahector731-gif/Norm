import 'dart:convert';

import 'package:uuid/uuid.dart';

enum TaskPriority { low, medium, high, urgent }

enum TaskFilter { all, active, done, overdue }

class TaskItem {
  String id;
  String title;
  bool isCompleted;
  DateTime? dueDate;
  String? category;
  TaskPriority priority;
  DateTime createdAt;
  int sortOrder;

  TaskItem({
    String? id,
    required this.title,
    this.isCompleted = false,
    this.dueDate,
    this.category,
    this.priority = TaskPriority.medium,
    DateTime? createdAt,
    this.sortOrder = 0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'dueDate': dueDate?.toIso8601String(),
        'category': category,
        'priority': priority.name,
        'createdAt': createdAt.toIso8601String(),
        'sortOrder': sortOrder,
      };

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
        id: json['id'] as String?,
        title: json['title'] as String? ?? '',
        isCompleted: json['isCompleted'] as bool? ?? false,
        dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'] as String) : null,
        category: json['category'] as String?,
        priority: TaskPriority.values.firstWhere(
          (e) => e.name == json['priority'],
          orElse: () => TaskPriority.medium,
        ),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        sortOrder: json['sortOrder'] as int? ?? 0,
      );

  bool get isOverdue =>
      !isCompleted && dueDate != null && dueDate!.isBefore(DateTime.now());

  bool get isDueToday =>
      dueDate != null &&
      dueDate!.year == DateTime.now().year &&
      dueDate!.month == DateTime.now().month &&
      dueDate!.day == DateTime.now().day;
}

class TaskBlock {
  static const String marker = '__norm_type__';
  static const String typeValue = 'task';

  String title;
  List<TaskItem> tasks;

  TaskBlock({
    this.title = 'Lista de Tareas',
    List<TaskItem>? tasks,
  }) : tasks = tasks ?? [];

  int get totalCount => tasks.length;
  int get completedCount => tasks.where((t) => t.isCompleted).length;
  int get activeCount => totalCount - completedCount;
  int get overdueCount => tasks.where((t) => t.isOverdue).length;

  List<TaskItem> filtered(TaskFilter filter) {
    var result = List<TaskItem>.from(tasks);
    switch (filter) {
      case TaskFilter.active:
        result = result.where((t) => !t.isCompleted).toList();
      case TaskFilter.done:
        result = result.where((t) => t.isCompleted).toList();
      case TaskFilter.overdue:
        result = result.where((t) => t.isOverdue).toList();
      case TaskFilter.all:
        break;
    }
    result.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      if (a.priority.index != b.priority.index) return b.priority.index - a.priority.index;
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return result;
  }

  void addTask(String title, {TaskPriority priority = TaskPriority.medium, DateTime? dueDate, String? category}) {
    if (title.trim().isEmpty) return;
    tasks.add(TaskItem(
      title: title.trim(),
      priority: priority,
      dueDate: dueDate,
      category: category?.trim(),
      sortOrder: tasks.length,
    ));
  }

  void toggleTask(String id) {
    final idx = tasks.indexWhere((t) => t.id == id);
    if (idx >= 0) tasks[idx].isCompleted = !tasks[idx].isCompleted;
  }

  void removeTask(String id) {
    tasks.removeWhere((t) => t.id == id);
  }

  void updateTask(String id, {String? title, bool? isCompleted, DateTime? dueDate, String? category, TaskPriority? priority}) {
    final idx = tasks.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    final task = tasks[idx];
    if (title != null) task.title = title;
    if (isCompleted != null) task.isCompleted = isCompleted;
    if (dueDate != null || dueDate == null && (title?.isEmpty ?? false) == false) {
      task.dueDate = dueDate;
    }
    if (category != null) task.category = category;
    if (priority != null) task.priority = priority;
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex--;
    final item = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, item);
    for (int i = 0; i < tasks.length; i++) tasks[i].sortOrder = i;
  }

  static final RegExp _nlpDate = RegExp(r'\b(today|tomorrow|next\s+\w+day|mon|tue|wed|thu|fri|sat|sun)\b', caseSensitive: false);
  static final RegExp _nlpPriority = RegExp(r'@(low|medium|high|urgent)\b', caseSensitive: false);
  static final RegExp _nlpCategory = RegExp(r'#(\w+)\b');

  void addFromNlp(String input) {
    if (input.trim().isEmpty) return;

    final priorityMatch = _nlpPriority.firstMatch(input);
    final priority = priorityMatch != null
        ? TaskPriority.values.firstWhere(
            (e) => e.name == priorityMatch.group(1)!.toLowerCase(),
            orElse: () => TaskPriority.medium,
          )
        : TaskPriority.medium;

    final categoryMatch = _nlpCategory.firstMatch(input);
    final category = categoryMatch?.group(1);

    final dateMatch = _nlpDate.firstMatch(input);
    final dueDate = dateMatch != null ? _parseDate(dateMatch.group(1)!) : null;

    String title = input;
    if (priorityMatch != null) title = title.replaceFirst(priorityMatch.group(0)!, '').trim();
    if (categoryMatch != null) title = title.replaceFirst(categoryMatch.group(0)!, '').trim();
    if (dateMatch != null) title = title.replaceFirst(dateMatch.group(0)!, '').trim();
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (title.isEmpty) return;
    addTask(title, priority: priority, dueDate: dueDate, category: category);
  }

  static DateTime? _parseDate(String text) {
    final now = DateTime.now();
    switch (text.toLowerCase()) {
      case 'today':
        return DateTime(now.year, now.month, now.day);
      case 'tomorrow':
        return DateTime(now.year, now.month, now.day + 1);
      case 'mon':
        return _nextWeekday(DateTime.monday);
      case 'tue':
        return _nextWeekday(DateTime.tuesday);
      case 'wed':
        return _nextWeekday(DateTime.wednesday);
      case 'thu':
        return _nextWeekday(DateTime.thursday);
      case 'fri':
        return _nextWeekday(DateTime.friday);
      case 'sat':
        return _nextWeekday(DateTime.saturday);
      case 'sun':
        return _nextWeekday(DateTime.sunday);
      default:
        if (text.startsWith('next ')) {
          final dayMap = {
            'monday': DateTime.monday, 'tuesday': DateTime.tuesday,
            'wednesday': DateTime.wednesday, 'thursday': DateTime.thursday,
            'friday': DateTime.friday, 'saturday': DateTime.saturday,
            'sunday': DateTime.sunday,
          };
          final day = dayMap[text.substring(5).toLowerCase()];
          if (day != null) return _nextWeekday(day, weeksAhead: 1);
        }
        return null;
    }
  }

  static DateTime _nextWeekday(int targetDay, {int weeksAhead = 0}) {
    final now = DateTime.now();
    final current = DateTime(now.year, now.month, now.day);
    int diff = targetDay - current.weekday;
    if (diff <= 0) diff += 7;
    return current.add(Duration(days: diff + (weeksAhead * 7)));
  }

  Map<String, dynamic> toJson() => {
        marker: typeValue,
        'title': title,
        'tasks': tasks.map((t) => t.toJson()).toList(),
      };

  factory TaskBlock.fromJson(Map<String, dynamic> json) => TaskBlock(
        title: json['title'] as String? ?? 'Lista de Tareas',
        tasks: (json['tasks'] as List?)
                ?.map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  String encode() => jsonEncode(toJson());

  static bool isTask(String contentJson) {
    try {
      return contentJson.trim().startsWith('{"$marker":"$typeValue"');
    } catch (_) {
      return false;
    }
  }

  factory TaskBlock.decode(String contentJson) {
    final data = jsonDecode(contentJson);
    return TaskBlock.fromJson(data as Map<String, dynamic>);
  }
}
