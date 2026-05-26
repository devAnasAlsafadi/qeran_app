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
    // Outer Container carries the shadow + rounded radius + gold
    // border. The ClipRRect inside clips the accent bar and the
    // stage content cleanly to the rounded corners.
    final shell = Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      decoration: BoxDecoration(
        color: QeranColors.paper,
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12431C33),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(color: QeranColors.gold, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Stack(
          children: [
            // Stage content. Asymmetric padding so the 4 dp accent bar
            // on the end edge doesn't crowd text/avatars.
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                16, 14, 20, 14,
              ),
              child: _buildStageContent(),
            ),
            // Gold accent bar — trailing edge (RTL: visual left,
            // alongside the avatar).
            PositionedDirectional(
              top: 0,
              bottom: 0,
              end: 0,
              child: Container(width: 4, color: QeranColors.gold),
            ),
            // "✓ توافق" chip — top-trailing corner.
            const PositionedDirectional(
              top: 12,
              end: 12,
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
