import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

import 'like_user_card.dart';

/// The top of every Matches-tab card: avatar, name, an optional trailing
/// action, the countdown chip, and the status line beneath.
///
/// Lifted out of [MatchCardScaffold] whole. The scaffold's job is the vertical
/// rhythm — header, primary action, helper, secondary actions, footer — and
/// the header was the one part carrying its own layout reasoning about how a
/// long Arabic name shares a row with a countdown.
///
/// ⚠️ The trailing edge of the name row is [trailing]'s, and the countdown
/// gets a line of its own beneath it. The chip used to sit on the name row,
/// and it does not fit there: measured with the shipped fonts against the
/// widest countdown the formatter produces, it took 118.6dp of a 170dp row at
/// 320dp and left the name 39.4dp — ellipsising real Arabic names before any
/// trailing action existed. Three of four (width, locale) combinations were
/// clipping. See `match_card_header_layout_test`.
///
/// The chip is the element that VARIES by state, so the chip is the one that
/// moves; [trailing] keeps a fixed position a member can learn. The chip line
/// is built only when there IS a chip — a card with nothing pending keeps its
/// old height exactly, which that same test pins to the number measured
/// before the move.
class MatchCardHeader extends StatelessWidget {
  const MatchCardHeader({
    super.key,
    required this.avatar,
    required this.name,
    required this.nameColor,
    required this.statusLine,
    this.topChip,
    this.trailing,
  });

  final Widget avatar;
  final String name;
  final Color nameColor;

  /// Already-built status row, so this widget stays layout-only.
  final Widget statusLine;

  /// Optional pending-countdown chip. Rendered on its own line under the
  /// name, NOT beside it — see the class doc.
  final Widget? topChip;

  /// Optional action pinned to the trailing edge of the name row. The cancel
  /// X on the Matches tab; null everywhere else.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        avatar,
        QeranSpacing.hs12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      textAlign: TextAlign.start,
                      style: QeranTypography.subtitle.copyWith(
                        color: nameColor,
                      ),
                      // Wraps rather than abbreviating — same rule as the
                      // likes row it sits beside on this screen.
                      maxLines: kLikeCardNameMaxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trailing != null) ...[QeranSpacing.hs8, trailing!],
                ],
              ),
              // Its own line, and only when there is one to draw.
              if (topChip != null) ...[
                const SizedBox(height: QeranSpacing.s6),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: topChip!,
                ),
              ],
              const SizedBox(height: QeranSpacing.s6),
              statusLine,
            ],
          ),
        ),
      ],
    );
  }
}

/// The icon + text line under the name, describing what the card is waiting
/// on. Moved here with the header it belongs to.
class MatchCardStatusLine extends StatelessWidget {
  const MatchCardStatusLine({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        QeranSpacing.hs4,
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.start,
            style: QeranTypography.bodySm.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
