import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';

/// Small count badge — a gold disc with wine numerals (never Material red).
/// Shared by the Users segmented control (pending count) and the
/// conversation rows (unread count). Caps the display at "99+".
class MatchmakerCountBadge extends StatelessWidget {
  const MatchmakerCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: const BoxDecoration(
        color: QeranColors.gold,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: QeranTypography.caption.copyWith(
          color: QeranColors.wine,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
