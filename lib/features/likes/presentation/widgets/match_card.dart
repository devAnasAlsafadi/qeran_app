import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/utils/app_dimens.dart';

import '../../domain/entities/match_card.dart';
import '../../domain/entities/match_stage.dart';
import 'match_card_stage0.dart';
import 'match_card_stage1.dart';
import 'match_card_stage2.dart';

/// One row in the Matches tab. Renders the stage-specific variant
/// inside a shared card shell so all three look like siblings.
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

  @override
  Widget build(BuildContext context) {
    final shell = Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12431C33),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.p16),
        child: _buildStageContent(),
      ),
    );
    if (onOpenProfile == null) return shell;
    return InkWell(
      onTap: onOpenProfile,
      borderRadius: BorderRadius.circular(22),
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
