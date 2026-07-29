import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';

import 'like_user_card.dart';

/// Shared body for every Matches-tab card so all stages read with one
/// padding + alignment rhythm.
///
/// Layout mirrors automatically by locale: the avatar sits on the
/// leading edge; the trailing side carries the live countdown chip
/// (if present) to keep headers consistent across states.
class MatchCardScaffold extends StatelessWidget {
  final Widget avatar;
  final String name;
  final IconData statusIcon;
  final String statusText;
  final Color statusColor;

  /// Optional pending-countdown chip, shown on the trailing edge of the row.
  final Widget? topChip;

  /// Optional primary action parameters. [primaryVariant] defaults to
  /// `primaryWine`; the Matches-tab stages pass `primary` (gold) while the
  /// shared matchmaker interest card keeps the wine default.
  final String? primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final bool primaryLoading;
  final IconData? primaryTrailingIcon;
  final QeranButtonVariant primaryVariant;

  /// Optional custom widget rendered in the primary-action region INSTEAD
  /// of the single [primaryLabel] button — used by the responder state to
  /// place a two-button (reject + accept) row the single slot can't express.
  final Widget? primaryOverride;

  /// Optional list of secondary actions (ghost buttons / text links)
  /// placed below the primary button.
  final List<Widget>? secondaryActions;

  /// Optional arbitrary footer content rendered below the action buttons.
  /// Used by the matchmaker interest card for answers + formal-status chips.
  final Widget? footer;

  const MatchCardScaffold({
    super.key,
    required this.avatar,
    required this.name,
    required this.statusIcon,
    required this.statusText,
    required this.statusColor,
    this.topChip,
    this.primaryLabel,
    this.onPrimaryPressed,
    this.primaryLoading = false,
    this.primaryTrailingIcon,
    this.primaryVariant = QeranButtonVariant.primaryWine,
    this.primaryOverride,
    this.secondaryActions,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
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
                          style: QeranTypography.subtitle
                              .copyWith(color: QeranColors.wine),
                          // Wraps rather than abbreviating — same rule as the
                          // likes row it sits beside on this screen.
                          maxLines: kLikeCardNameMaxLines,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (topChip != null) ...[
                        QeranSpacing.hs12,
                        topChip!,
                      ],
                    ],
                  ),
                  const SizedBox(height: QeranSpacing.s6),
                  _StatusLine(
                    icon: statusIcon,
                    text: statusText,
                    color: statusColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (primaryOverride != null) ...[
          const SizedBox(height: QeranSpacing.s12),
          primaryOverride!,
        ] else if (primaryLabel != null) ...[
          const SizedBox(height: QeranSpacing.s12),
          QeranButton(
            label: primaryLabel!,
            onPressed: onPrimaryPressed,
            variant: primaryVariant,
            size: QeranButtonSize.xs,
            loading: primaryLoading,
            trailingIcon: primaryTrailingIcon,
          ),
        ],
        if (secondaryActions != null && secondaryActions!.isNotEmpty) ...[
          const SizedBox(height: QeranSpacing.s8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: QeranSpacing.s8,
            runSpacing: QeranSpacing.s4,
            children: secondaryActions!,
          ),
        ],
        if (footer != null) ...[
          const SizedBox(height: QeranSpacing.s12),
          footer!,
        ],
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _StatusLine({
    required this.icon,
    required this.text,
    required this.color,
  });

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
