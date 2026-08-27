import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';

import 'match_card_header.dart';

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

  /// Optional explanatory line directly beneath the primary button — what
  /// pressing it actually sets in motion. Sits above [secondaryActions] so it
  /// stays attached to the action it describes.
  final String? primaryHelperText;

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
    this.primaryHelperText,
    this.secondaryActions,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MatchCardHeader(
          avatar: avatar,
          name: name,
          nameColor: QeranColors.wine,
          topChip: topChip,
          statusLine: MatchCardStatusLine(
            icon: statusIcon,
            text: statusText,
            color: statusColor,
          ),
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
        if (primaryHelperText != null) ...[
          const SizedBox(height: QeranSpacing.s6),
          Text(
            primaryHelperText!,
            textAlign: TextAlign.start,
            style: QeranTypography.caption.copyWith(color: QeranColors.inkBody),
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
