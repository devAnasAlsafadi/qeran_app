import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/likes_tab.dart';

/// Three-segment header on the Likes / Interests screen.
///
/// Wraps all cells in a single paper rounded card with a wine-tinted
/// shadow. The active indicator is an animated wine bar that slides
/// horizontally via `AnimatedPositionedDirectional`, so the position is
/// correct in both RTL and LTR without per-locale overrides.
class LikesSegmentedTabs extends StatelessWidget {
  final LikesTab active;
  final ValueChanged<LikesTab> onChanged;

  const LikesSegmentedTabs({
    super.key,
    required this.active,
    required this.onChanged,
  });

  static const Duration _kAnimDur = Duration(milliseconds: 280);
  static const double _kBarHeight = 3.0;
  static const double _kBarWidth = 40.0;
  static const double _kCardHeight = 56.0;
  static const double _kInnerPad = 4.0;

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
        height: _kCardHeight,
        decoration: BoxDecoration(
          color: QeranColors.paper,
          borderRadius: QeranRadii.cardR,
          border: Border.all(color: QeranColors.wine08),
          boxShadow: QeranShadows.e2,
        ),
        child: Padding(
          padding: const EdgeInsets.all(_kInnerPad),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = constraints.maxWidth / _order.length;
              final barStart =
                  activeIndex * cellWidth + (cellWidth - _kBarWidth) / 2;
              return Stack(
                children: [
                  AnimatedPositionedDirectional(
                    duration: _kAnimDur,
                    curve: Curves.easeOutCubic,
                    start: barStart,
                    bottom: 6,
                    width: _kBarWidth,
                    height: _kBarHeight,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: QeranColors.gold,
                        borderRadius: QeranRadii.pill,
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
      borderRadius: BorderRadius.circular(18),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: LikesSegmentedTabs._kAnimDur,
          curve: Curves.easeOutCubic,
          style: QeranTypography.subtitle.copyWith(
            color: isActive ? QeranColors.wine : QeranColors.inkMuted,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
          ),
          child: Text(
            labelKey.t(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
