import 'package:flutter/material.dart';

import '../../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../../core/design_system/tokens/qeran_typography.dart';

/// A row of her Dashboard's Community card (A2, A3): its disc, its label,
/// the count — wine, or gold for reports waiting, faint at 0 — and a
/// chevron. [divided] draws the line under it.
class CommunityDashboardRow extends StatelessWidget {
  const CommunityDashboardRow({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
    this.activeIcon,
    this.gold = false,
    this.divided = false,
  });

  final IconData icon;

  /// The icon while [count] is above 0, when it differs (reports' flag
  /// fills).
  final IconData? activeIcon;
  final String label;
  final int count;
  final VoidCallback onTap;

  /// Reports waiting: a gold disc and count once there are any.
  final bool gold;
  final bool divided;

  bool get _lit => gold && count > 0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label, $count',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            border: divided
                ? const Border(bottom: BorderSide(color: QeranColors.divider))
                : null,
          ),
          child: _content(),
        ),
      ),
    );
  }

  Widget _content() => Row(
    children: [
      _disc(),
      QeranSpacing.hs12,
      Expanded(
        child: Text(
          label,
          style: QeranTypography.body.copyWith(color: QeranColors.inkStrong),
        ),
      ),
      Text(
        '$count',
        style: QeranTypography.numeric.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: count == 0
              ? QeranColors.inkFaint
              : (_lit ? QeranColors.goldDeep : QeranColors.wine),
        ),
      ),
      QeranSpacing.hs4,
      const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: QeranColors.inkMuted,
      ),
    ],
  );

  Widget _disc() => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: _lit ? QeranColors.gold20 : QeranColors.softFill,
      borderRadius: QeranRadii.controlR,
    ),
    child: Icon(
      count > 0 ? (activeIcon ?? icon) : icon,
      size: 20,
      color: _lit ? QeranColors.goldDeep : QeranColors.wine,
    ),
  );
}
