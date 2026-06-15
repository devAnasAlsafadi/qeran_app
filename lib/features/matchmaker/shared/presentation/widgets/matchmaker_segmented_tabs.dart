import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_motion.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_shadows.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/extensions/localization_extension.dart';
import 'matchmaker_count_badge.dart';

/// One segment of a [MatchmakerSegmentedTabs].
class MatchmakerSegment {
  const MatchmakerSegment({required this.labelKey, this.badge = 0});

  final String labelKey;

  /// Optional count badge (e.g. pending users / unread). `0` hides it.
  final int badge;
}

/// Reusable segmented header: a paper card with a sliding gold indicator
/// that's RTL-correct via `AnimatedPositionedDirectional`. Used by the Users
/// tab (3 segments + a pending badge) and the Conversations tab (2 segments).
/// Tokenised on [QeranRadii] / [QeranShadows] — no raw literals.
class MatchmakerSegmentedTabs extends StatelessWidget {
  const MatchmakerSegmentedTabs({
    super.key,
    required this.segments,
    required this.activeIndex,
    required this.onChanged,
  });

  final List<MatchmakerSegment> segments;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  // Indicator glide + label cross-fade. Same tokens as the content slide, so
  // the bar travels in lockstep with the page transition.
  static const Duration _kAnimDur = QeranMotion.standard;
  static const Curve _kAnimCurve = QeranCurves.standard;
  static const double _kBarHeight = 3.0;
  static const double _kBarWidth = 40.0;
  static const double _kCardHeight = 56.0;
  static const double _kInnerPad = 4.0;

  @override
  Widget build(BuildContext context) {
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
              final cellWidth = constraints.maxWidth / segments.length;
              final barStart =
                  activeIndex * cellWidth + (cellWidth - _kBarWidth) / 2;
              return Stack(
                children: [
                  AnimatedPositionedDirectional(
                    duration: _kAnimDur,
                    curve: _kAnimCurve,
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
                      for (var i = 0; i < segments.length; i++)
                        Expanded(
                          child: _TabCell(
                            labelKey: segments[i].labelKey,
                            isActive: i == activeIndex,
                            badge: segments[i].badge,
                            onTap: () => onChanged(i),
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
  const _TabCell({
    required this.labelKey,
    required this.isActive,
    required this.badge,
    required this.onTap,
  });

  final String labelKey;
  final bool isActive;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: QeranRadii.controlR,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: MatchmakerSegmentedTabs._kAnimDur,
                curve: MatchmakerSegmentedTabs._kAnimCurve,
                style: QeranTypography.subtitle.copyWith(
                  fontSize: 14,
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
            if (badge > 0) ...[
              QeranSpacing.hs4,
              MatchmakerCountBadge(count: badge),
            ],
          ],
        ),
      ),
    );
  }
}
