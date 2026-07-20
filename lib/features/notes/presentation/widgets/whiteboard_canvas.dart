import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/database/database_service.dart';
import '../../domain/note_model.dart';

class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double width;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.width,
  });

  Map<String, dynamic> toJson() => {
    'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
    'color': color.value,
    'width': width,
  };

  static DrawingStroke fromJson(Map<String, dynamic> json) {
    final pts = (json['points'] as List)
        .map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
        .toList();
    return DrawingStroke(
      points: pts,
      color: Color(json['color'] as int),
      width: (json['width'] as num).toDouble(),
    );
  }
}

class WhiteboardCanvas extends StatefulWidget {
  final NoteModel note;

  const WhiteboardCanvas({super.key, required this.note});

  @override
  State<WhiteboardCanvas> createState() => _WhiteboardCanvasState();
}

class _WhiteboardCanvasState extends State<WhiteboardCanvas> {
  List<DrawingStroke> _strokes = [];
  List<Offset> _currentPoints = [];
  Color _selectedColor = const Color(0xff9d4edd);
  double _strokeWidth = 4.0;

  @override
  void initState() {
    super.initState();
    _loadStrokes();
  }

  void _loadStrokes() {
    final raw = widget.note.contentJson;
    if (raw.isNotEmpty && raw.trim().startsWith('[')) {
      try {
        final list = jsonDecode(raw) as List;
        _strokes = list
            .map((e) => DrawingStroke.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {}
    }
  }

  Future<void> _saveStrokes() async {
    final json = jsonEncode(_strokes.map((s) => s.toJson()).toList());
    widget.note.contentJson = json;
    widget.note.updatedAt = DateTime.now();
    await DatabaseService.saveNote(widget.note);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xff0d0e11) : const Color(0xffffffff),
      body: Stack(
        children: [
          GestureDetector(
            onPanStart: (details) {
              setState(() {
                _currentPoints = [details.localPosition];
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _currentPoints.add(details.localPosition);
              });
            },
            onPanEnd: (details) async {
              setState(() {
                _strokes.add(DrawingStroke(
                  points: List.from(_currentPoints),
                  color: _selectedColor,
                  width: _strokeWidth,
                ));
                _currentPoints.clear();
              });
              await _saveStrokes();
            },
            child: CustomPaint(
              painter: CanvasPainter(
                strokes: _strokes,
                currentPoints: _currentPoints,
                currentColor: _selectedColor,
                currentWidth: _strokeWidth,
              ),
              size: Size.infinite,
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: SafeArea(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.cardColor.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        color: _selectedColor,
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.auto_fix_normal_rounded),
                        onPressed: () {
                          setState(() => _strokes.clear());
                          _saveStrokes();
                        },
                      ),
                      const VerticalDivider(width: 20, color: Colors.grey),
                      _colorDot(const Color(0xff9d4edd)),
                      _colorDot(Colors.redAccent),
                      _colorDot(isDark ? Colors.white : Colors.black),
                      const VerticalDivider(width: 20, color: Colors.grey),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorDot(Color color) {
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _selectedColor == color ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class CanvasPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentWidth;

  CanvasPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var stroke in strokes) {
      paint.color = stroke.color;
      paint.strokeWidth = stroke.width;
      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }

    if (currentPoints.length > 1) {
      paint.color = currentColor;
      paint.strokeWidth = currentWidth;
      for (int i = 0; i < currentPoints.length - 1; i++) {
        canvas.drawLine(currentPoints[i], currentPoints[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) => true;
}
