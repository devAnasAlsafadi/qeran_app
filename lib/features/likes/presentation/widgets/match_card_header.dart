import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

import 'like_user_card.dart';

/// The top of every Matches-tab card: avatar, name, an optional trailing
/// chip, and the status line beneath.
///
/// Lifted out of [MatchCardScaffold] whole. The scaffold's job is the vertical
/// rhythm — header, primary action, helper, secondary actions, footer — and
/// the header was the one part carrying its own layout reasoning about how a
/// long Arabic name shares a row with a countdown.
class MatchCardHeader extends StatelessWidget {
  const MatchCardHeader({
    super.key,
    required this.avatar,
    required this.name,
    required this.nameColor,
    required this.statusLine,
    this.topChip,
  });

  final Widget avatar;
  final String name;
  final Color nameColor;

  /// Already-built status row, so this widget stays layout-only.
  final Widget statusLine;

  /// Optional pending-countdown chip, shown on the trailing edge of the name
  /// row.
  final Widget? topChip;

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
              // Name + countdown chip share the top line; the status sits
              // below at FULL column width so a long Arabic status wraps to
              // two lines instead of being squeezed by the trailing chip
              // and clipped with an ellipsis.
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
                  if (topChip != null) ...[QeranSpacing.hs12, topChip!],
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
