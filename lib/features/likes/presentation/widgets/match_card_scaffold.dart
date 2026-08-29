import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'match_card_header.dart';
import 'match_card_primary_region.dart';

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

  /// Optional pending-countdown chip, on a full-width line of its own between
  /// the identity block and the actions.
  ///
  /// It reports on a REQUEST, not on a person, so it does not belong inside
  /// [MatchCardHeader] — see that widget for the two measurements that moved
  /// it, first off the name row and then out of the header altogether.
  ///
  /// This position holds in every state, which is why it was chosen over the
  /// more obvious one. Anchoring the chip above the action buttons reads well
  /// on a card that HAS buttons and is undefined on the two that do not: the
  /// photo-exchange sender card carries no buttons at all, and an ended case
  /// withdraws the ones it had. Here it lands above the accept/decline pair
  /// for a responder, and directly under «بانتظار ردهم» for a sender — what
  /// is awaited, then how long is left — without a conditional either way.
  ///
  /// Withdrawn by [isEnded] along with the actions, and gated HERE rather than
  /// by the two resolvers that build it: one rule about an ended case, in one
  /// place, covering both pending kinds.
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
  /// One flag rather than a branch in each of the three stages. What it
  /// withdraws from the action region — the buttons and the helper line that
  /// captions them — is [MatchCardPrimaryRegion]'s to explain.
  ///
  /// The countdown chip goes too. A cancelled case whose pending block is
  /// still arriving from the server would otherwise tick «٢٣ ساعة و٣٢ دقيقة»
  /// toward a response nobody can give — the same lie as the helper line, one
  /// region higher, and on a sender card it is the ONLY live thing left. An
  /// ended case awaits nothing, so it counts down to nothing.
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
        // Start-aligned to the CARD's leading edge, not indented to the name
        // column, so it reads as the card's own line rather than as a stray
        // piece of the identity block. AlignmentDirectional, not centerLeft:
        // a hardcoded left is invisible in English and wrong in Arabic, which
        // is this app's default.
        if (!isEnded && topChip != null) ...[
          const SizedBox(height: QeranSpacing.s12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: topChip!,
          ),
        ],
        MatchCardPrimaryRegion(
          primaryLabel: primaryLabel,
          onPrimaryPressed: onPrimaryPressed,
          primaryLoading: primaryLoading,
          primaryTrailingIcon: primaryTrailingIcon,
          primaryVariant: primaryVariant,
          primaryOverride: primaryOverride,
          primaryHelperText: primaryHelperText,
          isEnded: isEnded,
        ),
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
