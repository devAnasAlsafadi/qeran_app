import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/core/utils/app_dimens.dart';

import '../../domain/entities/match_card.dart';
import '../../domain/entities/match_stage.dart';
import 'match_card_stage0.dart';
import 'match_card_stage1.dart';
import 'match_card_stage2.dart';

/// One row in the Matches tab. Renders the stage-specific variant
/// inside a shared **hero** shell — gold border, a 4 dp gold accent
/// bar running along the trailing edge (visual left in RTL, where the
/// avatar sits), and a `✓ توافق` chip at the top-trailing corner. The
/// hero treatment differentiates matches from the standard like-card
/// surfaces in the other Likes tabs.
class MatchCardWidget extends StatelessWidget {
  final MatchCard card;

  /// Stage 0 — request photo exchange CTA tap (when no pending).
  final VoidCallback? onRequestPhotoExchange;
  final bool isRequestingPhotoExchange;

  /// Stage 0 — accept/reject incoming photo-exchange request.
  final VoidCallback? onAcceptPhotoExchange;
  final VoidCallback? onRejectPhotoExchange;
  final bool isAcceptingPhotoExchange;
  final bool isRejectingPhotoExchange;

  /// Stage 0/1/2 — countdown reached zero locally.
  final VoidCallback? onPendingExpiredLocally;

  /// Stage 1 — avatar tap opens the gallery sheet.
  final VoidCallback? onOpenGallery;

  /// Stage 2 — contact-matchmaker CTA.
  final VoidCallback? onContactMatchmaker;

  /// Tap on the card background opens the reusable Full Profile
  /// Details screen with a match seed. Action buttons inside the card
  /// absorb their own taps before bubbling, so the stage-specific
  /// CTAs continue to fire independently.
  final VoidCallback? onOpenProfile;

  const MatchCardWidget({
    super.key,
    required this.card,
    this.onRequestPhotoExchange,
    this.isRequestingPhotoExchange = false,
    this.onAcceptPhotoExchange,
    this.onRejectPhotoExchange,
    this.isAcceptingPhotoExchange = false,
    this.isRejectingPhotoExchange = false,
    this.onPendingExpiredLocally,
    this.onOpenGallery,
    this.onContactMatchmaker,
    this.onOpenProfile,
  });

  static const double _radius = 22;

  @override
  Widget build(BuildContext context) {
    // Outer Container carries the shadow + rounded radius + 1.5 dp
    // gold border. A second wine-tinted glow shadow stacks under the
    // standard one to give matches a slightly warmer lift than other
    // Likes cards. The ClipRRect inside clips the accent bar and the
    // stage content cleanly to the rounded corners.
    final shell = Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      decoration: BoxDecoration(
        color: QeranColors.paper,
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: const [
          // Soft gold glow — only matches get this; makes the card feel
          // "earned" at a glance versus plain like-row cards.
          BoxShadow(
            color: Color(0x1FE4C094),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x12431C33),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(color: QeranColors.gold, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Stack(
          children: [
            // Stage content. Asymmetric padding leaves room on the
            // trailing edge for the 6 dp accent bar (alongside avatar)
            // and on the top-leading corner for the "توافق" badge.
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                16, 36, 22, 14,
              ),
              child: _buildStageContent(),
            ),
            // Gold accent bar — trailing edge (RTL: visual left,
            // alongside the avatar). 6 dp so it reads as a deliberate
            // accent next to the 1.5 dp border rather than merging
            // into it.
            PositionedDirectional(
              top: 0,
              bottom: 0,
              end: 0,
              child: Container(width: 6, color: QeranColors.gold),
            ),
            // "✓ توافق" chip — top-LEADING corner (RTL: visual right),
            // away from the avatar which sits on the trailing side.
            const PositionedDirectional(
              top: 12,
              start: 12,
              child: _MatchBadge(),
            ),
          ],
        ),
      ),
    );
    if (onOpenProfile == null) return shell;
    return InkWell(
      onTap: onOpenProfile,
      borderRadius: BorderRadius.circular(_radius),
      child: shell,
    );
  }

  Widget _buildStageContent() {
    switch (card.stage) {
      case MatchStage.waitingForPhotoExchange:
        return MatchCardStage0(
          card: card,
          onRequestPhotoExchange: onRequestPhotoExchange,
          isRequestingPhotoExchange: isRequestingPhotoExchange,
          onAcceptPhotoExchange: onAcceptPhotoExchange,
          onRejectPhotoExchange: onRejectPhotoExchange,
          isAcceptingPhotoExchange: isAcceptingPhotoExchange,
          isRejectingPhotoExchange: isRejectingPhotoExchange,
          onPendingExpiredLocally: onPendingExpiredLocally,
        );
      case MatchStage.photosExchanged:
        return MatchCardStage1(card: card, onOpenGallery: onOpenGallery);
      case MatchStage.matchmakerEngaged:
        return MatchCardStage2(
          card: card,
          onContactMatchmaker: onContactMatchmaker,
        );
      case MatchStage.unknown:
        return MatchCardStage2(card: card, onContactMatchmaker: null);
    }
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge();

  @override
  Widget build(BuildContext context) {
    return const QeranChip(
      label: 'توافق',
      variant: QeranChipVariant.interest,
      icon: Icons.check_circle_rounded,
      compact: true,
    );
  }
}
