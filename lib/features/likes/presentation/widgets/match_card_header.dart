import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

import 'like_user_card.dart';

/// The identity block of every Matches-tab card: avatar, name, an optional
/// trailing action, and the status line beneath.
///
/// ⚠️ The countdown chip is NOT here, and its absence is the design. It sat on
/// the name row first, and does not fit: measured with the shipped fonts
/// against the widest countdown the formatter produces, it took 118.6dp of a
/// 170dp row at 320dp and left the name 39.4dp — ellipsising real Arabic names
/// before any trailing action existed, in three of four (width, locale)
/// combinations. 5d moved it to its own line under the name, which fixed the
/// clipping and left a second problem: it is not identity information. It
/// reports on a REQUEST, and it was sitting in the block that answers who this
/// person is, taking 144.8dp of the 170dp name column at 320dp.
///
/// So it moved again, out of this widget entirely, to a full-width line the
/// scaffold owns between the status line and the actions. Both moves are
/// pinned by `match_card_header_layout_test`; the 118.6dp measurement is why
/// it must never come back to the name row.
///
/// The trailing edge of the name row is [trailing]'s, and it keeps a fixed
/// position a member can learn.
class MatchCardHeader extends StatelessWidget {
  const MatchCardHeader({
    super.key,
    required this.avatar,
    required this.name,
    required this.nameColor,
    required this.statusLine,
    this.trailing,
  });

  final Widget avatar;
  final String name;
  final Color nameColor;

  /// Already-built status row, so this widget stays layout-only.
  final Widget statusLine;

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
