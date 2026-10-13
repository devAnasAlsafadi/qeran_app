import 'package:flutter/widgets.dart';

import '../tokens/qeran_colors.dart';

/// Tab descriptor for [QeranBottomNav].
class QeranNavItem {
  final IconData outlineIcon;
  final IconData filledIcon;
  final String label;
  final int? badgeCount;
  final bool badgeIsDot;
  final Color badgeColor;

  const QeranNavItem({
    required this.outlineIcon,
    required this.filledIcon,
    required this.label,
    this.badgeCount,
    this.badgeIsDot = false,
    this.badgeColor = QeranColors.gold,
  });
}
