import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_shadows.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/matchmaker_users_list.dart';

/// Three-segment header for the Users tab. Cloned from the Likes
/// segmented control but tokenised on [QeranRadii] (no `BorderRadius.
/// circular` literals). The active indicator is a gold bar that slides
/// via `AnimatedPositionedDirectional` — correct in RTL and LTR. The
/// Pending segment carries a count badge fed from the dashboard.
class MatchmakerUsersSegmentedTabs extends StatelessWidget {
  final MatchmakerUsersList active;
  final ValueChanged<MatchmakerUsersList> onChanged;
  final int pendingBadge;

  const MatchmakerUsersSegmentedTabs({
    super.key,
    required this.active,
    required this.onChanged,
    this.pendingBadge = 0,
  });

  static const Duration _kAnimDur = Duration(milliseconds: 280);
  static const double _kBarHeight = 3.0;
  static const double _kBarWidth = 40.0;
  static const double _kCardHeight = 56.0;
  static const double _kInnerPad = 4.0;

  static const List<MatchmakerUsersList> _order = [
    MatchmakerUsersList.pending,
    MatchmakerUsersList.approvedUnsubscribed,
    MatchmakerUsersList.approvedSubscribed,
  ];

  String _labelKey(MatchmakerUsersList tab) => switch (tab) {
        MatchmakerUsersList.pending => LocaleKeys.matchmaker_users_tab_pending,
        MatchmakerUsersList.approvedUnsubscribed =>
          LocaleKeys.matchmaker_users_tab_approved_unsubscribed,
        MatchmakerUsersList.approvedSubscribed =>
          LocaleKeys.matchmaker_users_tab_approved_subscribed,
      };

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
                            badge: tab == MatchmakerUsersList.pending
                                ? pendingBadge
                                : 0,
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
  final int badge;
  final VoidCallback onTap;

  const _TabCell({
    required this.labelKey,
    required this.isActive,
    required this.badge,
    required this.onTap,
  });

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
                duration: MatchmakerUsersSegmentedTabs._kAnimDur,
                curve: Curves.easeOutCubic,
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
              _CountBadge(count: badge),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
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
