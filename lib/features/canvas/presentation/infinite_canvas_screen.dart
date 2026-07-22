import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../notes/domain/note_model.dart';
import '../../../core/database/database_service.dart';
import 'painters/canvas_grid_painter.dart';

class CanvasBlockData {
  String id;
  double x;
  double y;
  double width;
  double height;
  String title;
  String content;

  CanvasBlockData({
    required this.id,
    required this.x,
    required this.y,
    this.width = 200,
    this.height = 80,
    this.title = 'Nodo',
    this.content = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'title': title,
        'content': content,
      };

  factory CanvasBlockData.fromJson(Map<String, dynamic> json) =>
      CanvasBlockData(
        id: json['id'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['width'] as num?)?.toDouble() ?? 200,
        height: (json['height'] as num?)?.toDouble() ?? 80,
        title: json['title'] as String? ?? 'Nodo',
        content: json['content'] as String? ?? '',
      );
}

class InfiniteCanvasScreen extends StatefulWidget {
  final NoteModel note;

  const InfiniteCanvasScreen({super.key, required this.note});

  @override
  State<InfiniteCanvasScreen> createState() => _InfiniteCanvasScreenState();
}

class _InfiniteCanvasScreenState extends State<InfiniteCanvasScreen> {
  final TransformationController _transformCtrl = TransformationController();
  List<CanvasBlockData> _blocks = [];
  Timer? _saveTimer;
  int _saveGen = 0;

  @override
  void initState() {
    super.initState();
    _loadBlocks();
    _resetTransform();
  }

  void _loadBlocks() {
    try {
      final decoded = jsonDecode(widget.note.contentJson);
      if (decoded is Map && decoded['blocks'] is List) {
        _blocks = (decoded['blocks'] as List)
            .map((e) => CanvasBlockData.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
  }

  void _scheduleSave() {
    _saveGen++;
    final gen = _saveGen;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () async {
      if (gen != _saveGen) return;
      final data =
          jsonEncode({'blocks': _blocks.map((b) => b.toJson()).toList()});
      widget.note.contentJson = data;
      widget.note.updatedAt = DateTime.now();
      widget.note.isDirty = true;
      await DatabaseService.saveNote(widget.note);
    });
  }

  void _resetTransform() {
    _transformCtrl.value = Matrix4.identity()..translate(100, 100);
  }

  Rect _computeViewportRect(Size screenSize) {
    const margin = 200.0;
    final matrix = _transformCtrl.value;
    final inverse = Matrix4.inverted(matrix);
    final topLeft = MatrixUtils.transformPoint(inverse, Offset.zero);
    final bottomRight =
        MatrixUtils.transformPoint(inverse, Offset(screenSize.width, screenSize.height));
    return Rect.fromLTRB(
      topLeft.dx - margin,
      topLeft.dy - margin,
      bottomRight.dx + margin,
      bottomRight.dy + margin,
    );
  }

  List<CanvasBlockData> _visibleBlocks(Rect viewport) {
    return _blocks.where((b) {
      final rect = Rect.fromLTWH(b.x, b.y, b.width, b.height);
      return viewport.overlaps(rect);
    }).toList();
  }

  void _addBlock(Offset canvasPos) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    setState(() {
      _blocks.add(CanvasBlockData(
        id: id,
        x: canvasPos.dx - 100,
        y: canvasPos.dy - 40,
        title: 'Nodo ${_blocks.length + 1}',
      ));
    });
    _scheduleSave();
  }

  void _commitBlockPosition(String id, Offset pos) {
    final idx = _blocks.indexWhere((b) => b.id == id);
    if (idx < 0) return;
    _blocks[idx].x = pos.dx;
    _blocks[idx].y = pos.dy;
    _scheduleSave();
  }

  void _commitBlockSize(String id, double w, double h) {
    final idx = _blocks.indexWhere((b) => b.id == id);
    if (idx < 0) return;
    _blocks[idx].width = max(120, w);
    _blocks[idx].height = max(60, h);
    _scheduleSave();
  }

  void _commitBlockTitle(String id, String title) {
    final idx = _blocks.indexWhere((b) => b.id == id);
    if (idx < 0) return;
    _blocks[idx].title = title;
    _scheduleSave();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: GestureDetector(
        onDoubleTapDown: (details) {
          final matrix = _transformCtrl.value;
          final inverse = Matrix4.inverted(matrix);
          final canvasPos =
              MatrixUtils.transformPoint(inverse, details.localPosition);
          _addBlock(canvasPos);
        },
        child: InteractiveViewer(
          transformationController: _transformCtrl,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.1,
          maxScale: 4.0,
          child: AnimatedBuilder(
            animation: _transformCtrl,
            builder: (context, _) {
              final size = MediaQuery.of(context).size;
              final viewport = _computeViewportRect(size);
              final visible = _visibleBlocks(viewport);
              return SizedBox(
                width: 30000,
                height: 30000,
                child: CustomPaint(
                  painter: CanvasGridPainter(transform: _transformCtrl.value),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: visible.map((block) {
                      return Positioned(
                        left: block.x,
                        top: block.y,
                        child: RepaintBoundary(
                          child: _BlockCard(
                            key: ValueKey(block.id),
                            block: block,
                            onCommitPosition: (pos) =>
                                _commitBlockPosition(block.id, pos),
                            onCommitSize: (w, h) =>
                                _commitBlockSize(block.id, w, h),
                            onCommitTitle: (t) =>
                                _commitBlockTitle(block.id, t),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: const Color(0xFF3B82F6),
        onPressed: () => _addBlock(const Offset(500, 500)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _BlockCard extends StatefulWidget {
  final CanvasBlockData block;
  final ValueChanged<Offset> onCommitPosition;
  final void Function(double w, double h) onCommitSize;
  final ValueChanged<String> onCommitTitle;

  const _BlockCard({
    super.key,
    required this.block,
    required this.onCommitPosition,
    required this.onCommitSize,
    required this.onCommitTitle,
  });

  @override
  State<_BlockCard> createState() => _BlockCardState();
}

class _BlockCardState extends State<_BlockCard> {
  late TextEditingController _titleCtrl;
  Offset _dragOffset = Offset.zero;
  double _resizeDW = 0;
  double _resizeDH = 0;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.block.title);
  }

  @override
  void didUpdateWidget(_BlockCard old) {
    super.didUpdateWidget(old);
    if (old.block.id != widget.block.id) {
      _titleCtrl.text = widget.block.title;
      _dragOffset = Offset.zero;
      _resizeDW = 0;
      _resizeDH = 0;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _onDragEnd() {
    if (_dragOffset == Offset.zero) return;
    widget.onCommitPosition(widget.block.position + _dragOffset);
    setState(() => _dragOffset = Offset.zero);
  }

  void _onResizeEnd() {
    if (_resizeDW == 0 && _resizeDH == 0) return;
    widget.onCommitSize(widget.block.width + _resizeDW,
        widget.block.height + _resizeDH);
    setState(() {
      _resizeDW = 0;
      _resizeDH = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayW = widget.block.width + _resizeDW;
    final displayH = widget.block.height + _resizeDH;
    final clampedW = max(120, displayW);
    final clampedH = max(60, displayH);

    return Transform(
      transform: Matrix4.translationValues(_dragOffset.dx, _dragOffset.dy, 0),
      child: SizedBox(
        width: clampedW,
        child: GestureDetector(
          onPanStart: (_) => setState(() {}),
          onPanUpdate: (details) {
            setState(() => _dragOffset += details.delta);
          },
          onPanEnd: (_) => _onDragEnd(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: clampedW,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2E).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _titleCtrl,
                            style: const TextStyle(
                              color: Color(0xFFF8FAFC),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (v) {
                              widget.onCommitTitle(v);
                            },
                          ),
                        ),
                      ],
                    ),
                    if (widget.block.content.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.block.content,
                        style: const TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Resize handle
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onPanStart: (_) => setState(() {}),
                  onPanUpdate: (details) {
                    setState(() {
                      _resizeDW += details.delta.dx;
                      _resizeDH += details.delta.dy;
                    });
                  },
                  onPanEnd: (_) => _onResizeEnd(),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.8),
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(16),
                        topLeft: Radius.circular(6),
                      ),
                    ),
                    child: const Icon(
                      Icons.drag_handle,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on CanvasBlockData {
  Offset get position => Offset(x, y);
}
