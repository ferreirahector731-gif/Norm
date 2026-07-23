import 'package:flutter/material.dart';

import 'concentric_card.dart';

class GlassBentoCard extends StatelessWidget {
  final double? height;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const GlassBentoCard({
    super.key,
    this.height,
    required this.child,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ConcentricCard(
      level: ConcentricLevel.outer,
      height: height,
      padding: padding ?? const EdgeInsets.all(20),
      onTap: onTap,
      child: child,
    );
  }
}
