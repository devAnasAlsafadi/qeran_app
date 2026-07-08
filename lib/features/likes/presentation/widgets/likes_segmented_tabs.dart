import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_motion.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/likes_tab.dart';

/// Three-segment header on the Likes / Interests screen.
///
/// A cream track holds a single white paper "pill" that slides to sit behind
/// the active segment via `AnimatedPositionedDirectional`, so the position is
/// correct in both RTL and LTR without per-locale overrides. Motion, radii and
/// shadow all come from tokens — the slide uses the hero curve for a smooth,
/// spring-like settle.
class LikesSegmentedTabs extends StatelessWidget {
  final LikesTab active;
  final ValueChanged<LikesTab> onChanged;

  const LikesSegmentedTabs({
    super.key,
    required this.active,
    required this.onChanged,
  });

  static const double _kTrackHeight = 56.0;
  static const double _kInnerPad = 5.0;

  static const List<LikesTab> _order = [
    LikesTab.sent,
    LikesTab.received,
    LikesTab.matches,
  ];

  String _labelKey(LikesTab tab) {
    switch (tab) {
      case LikesTab.sent:
        return LocaleKeys.likes_tab_sent;
      case LikesTab.received:
        return LocaleKeys.likes_tab_received;
      case LikesTab.matches:
        return LocaleKeys.likes_tab_matches;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _order.indexOf(active);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s8,
        QeranSpacing.s20,
        QeranSpacing.s12,
      ),
      child: Container(
        height: _kTrackHeight,
        decoration: const BoxDecoration(
          color: QeranColors.creamSurface,
          borderRadius: QeranRadii.pill,
        ),
        padding: const EdgeInsets.all(_kInnerPad),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth = constraints.maxWidth / _order.length;
            return Stack(
              children: [
                AnimatedPositionedDirectional(
                  duration: QeranMotion.standard,
                  curve: QeranCurves.hero,
                  start: activeIndex * cellWidth,
                  top: 0,
                  bottom: 0,
                  width: cellWidth,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: QeranColors.paper,
                      borderRadius: QeranRadii.pill,
                      boxShadow: QeranShadows.e1,
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final tab in _order)
                      Expanded(
                        child: _TabCell(
                          labelKey: _labelKey(tab),
                          isActive: tab == active,
                          onTap: () => onChanged(tab),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TabCell extends StatelessWidget {
  final String labelKey;
  final bool isActive;
  final VoidCallback onTap;

  const _TabCell({
    required this.labelKey,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: QeranRadii.pill,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: QeranMotion.standard,
          curve: QeranCurves.standard,
          style: QeranTypography.subtitle.copyWith(
            color: isActive ? QeranColors.wine : QeranColors.inkMuted,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
          ),
          child: Text(
            labelKey.t(context),
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
