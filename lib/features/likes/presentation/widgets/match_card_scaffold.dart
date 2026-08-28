import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'match_card_header.dart';

/// Shared body for every Matches-tab card so all stages read with one
/// padding + alignment rhythm.
///
/// Layout mirrors automatically by locale: the avatar sits on the leading
/// edge, and the trailing edge of the name row belongs to [headerTrailing].
///
/// Three callers, all in this folder: `match_card_stage0`, `_stage1` and
/// `_stage2`. This doc used to name a shared matchmaker interest card as a
/// fourth — no matchmaker file has ever referenced this widget.
class MatchCardScaffold extends StatelessWidget {
  final Widget avatar;
  final String name;
  final IconData statusIcon;
  final String statusText;
  final Color statusColor;

  /// Optional pending-countdown chip. [MatchCardHeader] gives it a line of
  /// its own beneath the name — it does not fit beside one.
  final Widget? topChip;

  /// Optional action pinned to the trailing edge of the name row: the cancel
  /// X on the Matches tab, and nothing anywhere else.
  final Widget? headerTrailing;

  /// Optional primary action parameters. [primaryVariant] defaults to
  /// `primaryWine`; all three Matches-tab stages pass `primary` (gold).
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
  /// The Matches stages put the compatibility journey here.
  final Widget? footer;

  /// Whether the compatibility journey has stopped — `matchJourneyHasEnded`,
  /// which each stage reads off its own card.
  ///
  /// One flag rather than a branch in each of the three stages, and it lands
  /// here rather than in them because every control it has to withdraw is in
  /// the primary region THIS widget owns: the stage-0 photo CTA and the
  /// accept/decline pair, and the stage-1/2 formal CTA and its responder
  /// buttons all arrive as [primaryLabel] or [primaryOverride].
  ///
  /// It takes [primaryHelperText] with them, which is the reason the flag
  /// belongs at this seam rather than at each caller. On an ended case that
  /// line reads «ستتواصل معك الخطّابة للتنسيق للقاء الرسمي مع الأهل» — a
  /// promise about a meeting nobody is arranging. Withdrawing the button and
  /// leaving its caption behind would have been the worse half-fix.
  ///
  /// [secondaryActions] deliberately SURVIVES. The only thing there is the
  /// stage-0 «أرسل استفساراتك للخطّابة», and asking the matchmaker is exactly
  /// what a member whose case just ended may want to do — the server's own
  /// closing notice invites it.
  ///
  /// The status line is replaced rather than suppressed, because a card with
  /// no line at all reads as broken rather than as finished. What it says is
  /// forward-looking: the journey row below already reports what happened, so
  /// this one answers what now, and the two stay in different registers.
  final bool isEnded;

  const MatchCardScaffold({
    super.key,
    required this.avatar,
    required this.name,
    required this.statusIcon,
    required this.statusText,
    required this.statusColor,
    this.topChip,
    this.headerTrailing,
    this.primaryLabel,
    this.onPrimaryPressed,
    this.primaryLoading = false,
    this.primaryTrailingIcon,
    this.primaryVariant = QeranButtonVariant.primaryWine,
    this.primaryOverride,
    this.primaryHelperText,
    this.secondaryActions,
    this.footer,
    this.isEnded = false,
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
          trailing: headerTrailing,
          statusLine: isEnded
              // Muted, not danger. The journey row underneath already carries
              // the ending in danger with a cross; a second red line stacked
              // on top of it would shout, and this line is the calm half of
              // the pair.
              ? MatchCardStatusLine(
                  icon: Icons.search_rounded,
                  text: LocaleKeys.likes_matches_stage_ended_subtitle.t(
                    context,
                  ),
                  color: QeranColors.inkMuted,
                )
              : MatchCardStatusLine(
                  icon: statusIcon,
                  text: statusText,
                  color: statusColor,
                ),
        ),
        // The whole primary region under ONE guard, helper included. The
        // helper is a separate `if` from the button it captions — it has to
        // be, since the responder state has a button and no helper — so
        // guarding only the button would have withdrawn the action and left
        // its caption promising a meeting nobody is arranging.
        if (!isEnded) ...[
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
              style: QeranTypography.caption.copyWith(
                color: QeranColors.inkBody,
              ),
            ),
          ],
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
