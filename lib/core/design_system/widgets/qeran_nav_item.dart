import 'package:flutter/widgets.dart';

import '../tokens/qeran_colors.dart';

/// Tab descriptor for [QeranBottomNav]: a pair of Material icons, or — for a
/// tab drawn by us ([QeranNavItem.svg]) — a pair of SVG assets on the same
/// 24 grid and 2-unit stroke, so it sits with the icons.
class QeranNavItem {
  /// The tab unselected (outline, muted), and selected (filled, wine, on the
  /// gold disc). Null on an SVG tab.
  final IconData? outlineIcon;
  final IconData? filledIcon;

  /// The same two states as SVG asset paths. Null on an icon tab.
  final String? outlineSvg;
  final String? filledSvg;
  final String label;
  final int? badgeCount;
  final bool badgeIsDot;
  final Color badgeColor;

  const QeranNavItem({
    required IconData this.outlineIcon,
    required IconData this.filledIcon,
    required this.label,
    this.badgeCount,
    this.badgeIsDot = false,
    this.badgeColor = QeranColors.gold,
  }) : outlineSvg = null,
       filledSvg = null;

  const QeranNavItem.svg({
    required String this.outlineSvg,
    required String this.filledSvg,
    required this.label,
    this.badgeCount,
    this.badgeIsDot = false,
    this.badgeColor = QeranColors.gold,
  }) : outlineIcon = null,
       filledIcon = null;
}
