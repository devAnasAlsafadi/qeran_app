import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/likes_tab.dart';

/// Three-segment header on the Likes / Interests screen.
///
/// Wraps all cells in a single white rounded card with a soft burgundy
/// shadow — matches the Figma "pill" style. The active indicator is an
/// animated burgundy bar that slides horizontally inside the card via
/// `AnimatedPositionedDirectional`, so the position is correct in both
/// RTL and LTR without per-locale overrides.
///
/// Tab order is `[sent, received, matches]` so in Arabic (RTL) `Sent`
/// sits on the right, `Received` in the middle and `Matches` on the
/// left; in English (LTR) they flip automatically.
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
  static const double _kCardRadius = 22.0;
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
        AppDimens.p20,
        AppDimens.p8,
        AppDimens.p20,
        AppDimens.p12,
      ),
      child: Container(
        height: _kCardHeight,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(_kCardRadius),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.06),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10431C33), // primary @ ~6 %
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
          ],
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
                  // Bottom-aligned animated underline. Directional Start
                  // means RTL-correct positioning without extra logic.
                  AnimatedPositionedDirectional(
                    duration: _kAnimDur,
                    curve: Curves.easeOutCubic,
                    start: barStart,
                    bottom: 6,
                    width: _kBarWidth,
                    height: _kBarHeight,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.all(Radius.circular(2)),
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

  static const Color _active = AppColors.primary;
  static const Color _inactive = AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: LikesSegmentedTabs._kAnimDur,
          curve: Curves.easeOutCubic,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isActive ? _active : _inactive,
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
