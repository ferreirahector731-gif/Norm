import 'package:flutter/material.dart';

import 'painters/canvas_grid_painter.dart';

class CanvasNode {
  final String id;
  Offset position;
  Size size;
  String title;
  String content;

  CanvasNode({
    required this.id,
    required this.position,
    this.size = const Size(200, 80),
    this.title = 'Nodo',
    this.content = '',
  });

  Rect get rect => Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
}

class InfiniteCanvasScreen extends StatefulWidget {
  const InfiniteCanvasScreen({super.key});

  @override
  State<InfiniteCanvasScreen> createState() => _InfiniteCanvasScreenState();
}

class _InfiniteCanvasScreenState extends State<InfiniteCanvasScreen> {
  final TransformationController _transformCtrl = TransformationController();
  final List<CanvasNode> _nodes = [];
  String _nextId = '1';

  @override
  void initState() {
    super.initState();
    _resetTransform();
  }

  void _resetTransform() {
    _transformCtrl.value = Matrix4.identity()
      ..translate(100, 100);
  }

  Rect _computeViewportRect(Size screenSize) {
    final matrix = _transformCtrl.value;
    final inverse = Matrix4.inverted(matrix);
    final topLeft = MatrixUtils.transformPoint(inverse, Offset.zero);
    final bottomRight =
        MatrixUtils.transformPoint(inverse, Offset(screenSize.width, screenSize.height));
    return Rect.fromLTRB(topLeft.dx, topLeft.dy, bottomRight.dx, bottomRight.dy);
  }

  List<CanvasNode> _visibleNodes(Rect viewport) {
    return _nodes.where((n) => viewport.overlaps(n.rect)).toList();
  }

  void _addNode(Offset canvasPos) {
    setState(() {
      _nodes.add(CanvasNode(
        id: _nextId,
        position: canvasPos - const Offset(100, 40),
        title: 'Nodo $_nextId',
      ));
      _nextId = (_nextId.isEmpty ? '0' : (int.parse(_nextId) + 1).toString());
    });
  }

  void _updateNodePosition(String id, Offset newPos) {
    setState(() {
      final idx = _nodes.indexWhere((n) => n.id == id);
      if (idx >= 0) _nodes[idx].position = newPos;
    });
  }

  @override
  void dispose() {
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
          final canvasPos = MatrixUtils.transformPoint(inverse, details.localPosition);
          _addNode(canvasPos);
        },
        child: InteractiveViewer(
          transformationController: _transformCtrl,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.1,
          maxScale: 4.0,
          onInteractionUpdate: (_) => setState(() {}),
          child: SizedBox(
            width: 30000,
            height: 30000,
            child: CustomPaint(
              painter: CanvasGridPainter(transform: _transformCtrl.value),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ..._buildVisibleNodes(MediaQuery.of(context).size),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: const Color(0xFF3B82F6),
        onPressed: () => _addNode(const Offset(500, 500)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<Widget> _buildVisibleNodes(Size screenSize) {
    final viewport = _computeViewportRect(screenSize);
    final visible = _visibleNodes(viewport);

    return visible.map((node) {
      return Positioned(
        left: node.position.dx,
        top: node.position.dy,
        child: _NodeCard(
          node: node,
          onPositionChanged: (offset) => _updateNodePosition(node.id, offset),
        ),
      );
    }).toList();
  }
}

class _NodeCard extends StatefulWidget {
  final CanvasNode node;
  final ValueChanged<Offset> onPositionChanged;

  const _NodeCard({required this.node, required this.onPositionChanged});

  @override
  State<_NodeCard> createState() => _NodeCardState();
}

class _NodeCardState extends State<_NodeCard> {
  late TextEditingController _titleCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.node.title);
  }

  @override
  void didUpdateWidget(_NodeCard old) {
    super.didUpdateWidget(old);
    if (old.node.id != widget.node.id) {
      _titleCtrl.text = widget.node.title;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        widget.onPositionChanged(widget.node.position + details.delta);
      },
      child: Container(
        width: widget.node.size.width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF131B2E).withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
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
                    onChanged: (v) => widget.node.title = v,
                  ),
                ),
              ],
            ),
            if (widget.node.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.node.content,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
