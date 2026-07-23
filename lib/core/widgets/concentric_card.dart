import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';

enum ConcentricLevel { outer, inner, innerMost }

class ConcentricCard extends StatelessWidget {
  final ConcentricLevel level;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final BoxBorder? border;

  const ConcentricCard({
    super.key,
    this.level = ConcentricLevel.outer,
    required this.child,
    this.onTap,
    this.padding,
    this.height,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normTheme = context.read<ThemeProvider>().theme;
    final radius = _computeRadius(normTheme);
    final blur = _computeBlur(normTheme);

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: blur > 0
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: _buildContainer(context, radius),
            )
          : _buildContainer(context, radius),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: card,
        ),
      );
    }

    return card;
  }

  double _computeRadius(NormTheme t) {
    switch (level) {
      case ConcentricLevel.outer:
        return t.cardRadius;
      case ConcentricLevel.inner:
        return t.innerRadius;
      case ConcentricLevel.innerMost:
        return t.innerMostRadius;
    }
  }

  double _computeBlur(NormTheme t) {
    switch (level) {
      case ConcentricLevel.outer:
        return t.liquidBlur;
      case ConcentricLevel.inner:
        return t.liquidBlur * 0.75;
      case ConcentricLevel.innerMost:
        return t.liquidBlur * 0.5;
    }
  }

  Widget _buildContainer(BuildContext context, double radius) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer.withOpacity(0.85),
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(
          color: scheme.outline.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
