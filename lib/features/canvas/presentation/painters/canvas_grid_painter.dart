import 'dart:ui' show Canvas, Paint, Rect, Offset, Size;

import 'package:flutter/material.dart';

class CanvasGridPainter extends CustomPainter {
  final Matrix4 transform;
  final double gridSize;
  final Color lineColor;
  final Color majorLineColor;

  CanvasGridPainter({
    required this.transform,
    this.gridSize = 40,
    this.lineColor = const Color(0x1AFFFFFF),
    this.majorLineColor = const Color(0x2AFFFFFF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = transform.getMaxScaleOnAxis();
    final inverse = Matrix4.inverted(transform);

    // Visible viewport in canvas coordinates
    final origin = MatrixUtils.transformPoint(inverse, Offset.zero);
    final far = MatrixUtils.transformPoint(
        inverse, Offset(size.width, size.height));

    final visibleLeft = origin.dx;
    final visibleTop = origin.dy;
    final visibleRight = far.dx;
    final visibleBottom = far.dy;

    final step = _adaptiveStep(scale);
    final invertedScale = inverse.getMaxScaleOnAxis();

    final paint = Paint()
      ..style = PaintingStyle.stroke;

    // Vertical lines
    final startX = (visibleLeft / step).floor() * step;
    for (double x = startX; x <= visibleRight; x += step) {
      final isMajor = x % (step * 5) == 0;
      paint.color = isMajor ? majorLineColor : lineColor;
      paint.strokeWidth = isMajor ? 1.0 * invertedScale : 0.5 * invertedScale;
      canvas.drawLine(Offset(x, visibleTop), Offset(x, visibleBottom), paint);
    }

    // Horizontal lines
    final startY = (visibleTop / step).floor() * step;
    for (double y = startY; y <= visibleBottom; y += step) {
      final isMajor = y % (step * 5) == 0;
      paint.color = isMajor ? majorLineColor : lineColor;
      paint.strokeWidth = isMajor ? 1.0 * invertedScale : 0.5 * invertedScale;
      canvas.drawLine(Offset(visibleLeft, y), Offset(visibleRight, y), paint);
    }
  }

  double _adaptiveStep(double scale) {
    if (scale > 1.5) return gridSize;
    if (scale > 0.8) return gridSize * 2;
    return gridSize * 4;
  }

  @override
  bool shouldRepaint(CanvasGridPainter oldDelegate) =>
      oldDelegate.transform != transform;
}
