import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';

enum QeranSurfaceTier {
  /// Cream canvas — scaffold backgrounds.
  canvas,

  /// Slightly elevated cream — secondary surfaces inside canvas.
  creamLifted,

  /// White paper — lifted cards on cream.
  paper,

  /// Deep burgundy — hero moments, splash, paywall, match-success.
  wineDeep,
}

/// Tier-aware background container. Use this instead of raw Containers
/// for any top-level surface so the brand hierarchy is preserved.
class QeranSurface extends StatelessWidget {
  const QeranSurface({
    super.key,
    required this.child,
    this.tier = QeranSurfaceTier.canvas,
    this.padding,
  });

  final Widget child;
  final QeranSurfaceTier tier;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final bg = switch (tier) {
      QeranSurfaceTier.canvas => QeranColors.creamCanvas,
      QeranSurfaceTier.creamLifted => QeranColors.creamSurface,
      QeranSurfaceTier.paper => QeranColors.paper,
      QeranSurfaceTier.wineDeep => QeranColors.wine,
    };

    return Container(
      color: bg,
      padding: padding,
      child: child,
    );
  }
}
