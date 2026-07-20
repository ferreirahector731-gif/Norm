import 'dart:math' show sin, pi;

import 'package:flutter/material.dart';

class Shimmer extends StatefulWidget {
  final Widget child;

  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Stack(
        children: [
          child!,
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ShimmerPainter(animation: _controller),
              ),
            ),
          ),
        ],
      ),
      child: widget.child,
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final Animation<double> animation;

  _ShimmerPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final phase = sin(animation.value * 2 * pi);
    final center = (phase + 1) / 2;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.08),
          Colors.transparent,
        ],
        stops: [
          (center - 0.25).clamp(0.0, 1.0),
          center.clamp(0.0, 1.0),
          (center + 0.25).clamp(0.0, 1.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.animation != animation;
}

class ShimmerBentoGrid extends StatelessWidget {
  const ShimmerBentoGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _skeletonCard(
                    context,
                    scheme,
                    height: 120,
                    margin: const EdgeInsets.only(right: 4),
                  ),
                ),
                Expanded(
                  child: _skeletonCard(
                    context,
                    scheme,
                    height: 90,
                    margin: const EdgeInsets.only(left: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _skeletonCard(
                    context,
                    scheme,
                    height: 90,
                    margin: const EdgeInsets.only(right: 4),
                  ),
                ),
                Expanded(
                  child: _skeletonCard(
                    context,
                    scheme,
                    height: 120,
                    margin: const EdgeInsets.only(left: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _skeletonCard(
                    context,
                    scheme,
                    height: 110,
                    margin: const EdgeInsets.only(right: 4),
                  ),
                ),
                Expanded(
                  child: _skeletonCard(
                    context,
                    scheme,
                    height: 80,
                    margin: const EdgeInsets.only(left: 4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonCard(
    BuildContext context,
    ColorScheme scheme, {
    required double height,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 16,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 80,
            height: 10,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class ShimmerEditor extends StatelessWidget {
  const ShimmerEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.only(left: 56, right: 56, top: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _skeletonLine(
              scheme,
              width: 220,
              height: 32,
            ),
            const SizedBox(height: 24),
            _skeletonLine(scheme, width: double.infinity, height: 14),
            const SizedBox(height: 12),
            _skeletonLine(scheme, width: double.infinity, height: 14),
            const SizedBox(height: 12),
            _skeletonLine(scheme, width: 280, height: 14),
            const SizedBox(height: 32),
            _skeletonLine(scheme, width: double.infinity, height: 14),
            const SizedBox(height: 12),
            _skeletonLine(scheme, width: 320, height: 14),
            const SizedBox(height: 12),
            _skeletonLine(scheme, width: double.infinity, height: 14),
            const SizedBox(height: 12),
            _skeletonLine(scheme, width: 180, height: 14),
            const SizedBox(height: 32),
            _skeletonLine(scheme, width: double.infinity, height: 14),
            const SizedBox(height: 12),
            _skeletonLine(scheme, width: 360, height: 14),
          ],
        ),
      ),
    );
  }

  Widget _skeletonLine(
    ColorScheme scheme, {
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withOpacity(0.25),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
