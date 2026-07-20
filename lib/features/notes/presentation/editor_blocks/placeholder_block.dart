import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'custom_block_keys.dart';

class PlaceholderBlockComponentBuilder extends BlockComponentBuilder {
  final String blockType;
  final IconData iconData;
  final String label;

  PlaceholderBlockComponentBuilder({
    super.configuration,
    required this.blockType,
    required this.iconData,
    required this.label,
  });

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return PlaceholderBlockComponentWidget(
      key: node.key,
      node: node,
      showActions: showActions(node),
      configuration: configuration,
      actionBuilder: (context, state) =>
          actionBuilder(blockComponentContext, state),
      actionTrailingBuilder: (context, state) =>
          actionTrailingBuilder(blockComponentContext, state),
      iconData: iconData,
      label: label,
    );
  }

  @override
  BlockComponentValidate get validate =>
      (node) => node.delta == null && node.children.isEmpty;
}

class PlaceholderBlockComponentWidget extends BlockComponentStatefulWidget {
  const PlaceholderBlockComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.actionTrailingBuilder,
    super.configuration = const BlockComponentConfiguration(),
    required this.iconData,
    required this.label,
  });

  final IconData iconData;
  final String label;

  @override
  State<PlaceholderBlockComponentWidget> createState() =>
      _PlaceholderBlockComponentWidgetState();
}

class _PlaceholderBlockComponentWidgetState
    extends State<PlaceholderBlockComponentWidget>
    with SelectableMixin, BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  late final editorState = Provider.of<EditorState>(context, listen: false);

  @override
  Widget build(BuildContext context) {
    final caption =
        widget.node.attributes[ImagePlaceholderKeys.caption] as String? ?? '';

    Widget child = Container(
      height: 160,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.iconData,
                size: 28, color: Colors.white.withValues(alpha: 0.25)),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (caption.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                caption,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    child = BlockSelectionContainer(
      node: node,
      delegate: this,
      listenable: editorState.selectionNotifier,
      blockColor: editorState.editorStyle.selectionColor,
      supportTypes: const [BlockSelectionType.block],
      child: child,
    );

    if (widget.showActions && widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: node,
        actionBuilder: widget.actionBuilder!,
        actionTrailingBuilder: widget.actionTrailingBuilder,
        child: child,
      );
    }

    return child;
  }

  @override
  Position start() => Position(path: widget.node.path, offset: 0);

  @override
  Position end() => Position(path: widget.node.path, offset: 1);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  bool get shouldCursorBlink => false;

  @override
  CursorStyle get cursorStyle => CursorStyle.cover;

  @override
  Rect getBlockRect({bool shiftWithBaseOffset = false}) {
    final renderBox = context.findRenderObject() as RenderBox?;
    return renderBox != null ? Offset.zero & renderBox.size : Rect.zero;
  }

  @override
  Rect? getCursorRectInPosition(Position position,
      {bool shiftWithBaseOffset = false}) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    return Rect.fromLTWH(0, 0, renderBox.size.width, renderBox.size.height);
  }

  @override
  List<Rect> getRectsInSelection(Selection selection,
      {bool shiftWithBaseOffset = false}) {
    final renderBox = context.findRenderObject() as RenderBox?;
    return renderBox != null ? [Offset.zero & renderBox.size] : [];
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) =>
      Selection.single(path: widget.node.path, startOffset: 0, endOffset: 1);

  @override
  Offset localToGlobal(Offset offset,
          {bool shiftWithBaseOffset = false}) =>
      (context.findRenderObject() as RenderBox).localToGlobal(offset);
}
