import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_strokes.dart';

import '../../domain/entities/match_card.dart';
import '../../domain/entities/match_stage.dart';
import 'match_card_stage0.dart';
import 'match_card_stage1.dart';
import 'match_card_stage2.dart';

/// One row in the Matches tab. Renders the stage-specific variant inside
/// a shared "earned" shell — a gold hairline border + soft gold-glow
/// elevation ([QeranShadows.eHero]) that sets matches apart from the
/// plain like-row cards. Every stage flows through `MatchCardScaffold`,
/// so internal padding + rhythm are identical; only the stage content
/// (CTA vs countdown vs gallery) changes.
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

  /// Stage 0 — inquiry CTA (shares the profile + predefined text).
  final VoidCallback? onContactMatchmaker;
  final bool isInquirySending;
  final bool isInquirySent;

  /// Stage 1/2 — formal-step CTA: shares the partner card + message into
  /// the matchmaker chat, then opens it (guarded once per session).
  final VoidCallback? onFormalStep;
  final bool isFormalStepSending;
  final bool isFormalStepSent;

  /// Tap on the card background opens the reusable Full Profile Details
  /// screen with a match seed. Action buttons inside the card absorb
  /// their own taps, so the stage CTAs continue to fire independently.
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
    this.isInquirySending = false,
    this.isInquirySent = false,
    this.onFormalStep,
    this.isFormalStepSending = false,
    this.isFormalStepSent = false,
    this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    final shell = Container(
      margin: const EdgeInsets.only(bottom: QeranSpacing.s12),
      decoration: BoxDecoration(
        color: QeranColors.paper,
        borderRadius: QeranRadii.cardR,
        boxShadow: QeranShadows.eHero,
        border: Border.all(
          color: QeranColors.gold,
          width: QeranStrokes.hairline,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(QeranSpacing.s16),
        child: _buildStageContent(),
      ),
    );
    if (onOpenProfile == null) return shell;
    return Material(
      color: Colors.transparent,
      borderRadius: QeranRadii.cardR,
      child: InkWell(
        borderRadius: QeranRadii.cardR,
        onTap: onOpenProfile,
        child: shell,
      ),
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
          onContactMatchmaker: onContactMatchmaker,
          isInquirySending: isInquirySending,
          isInquirySent: isInquirySent,
        );
      case MatchStage.photosExchanged:
        return MatchCardStage1(
          card: card,
          onOpenGallery: onOpenGallery,
          onFormalStep: onFormalStep,
          isFormalStepSending: isFormalStepSending,
          isFormalStepSent: isFormalStepSent,
        );
      case MatchStage.matchmakerEngaged:
        return MatchCardStage2(
          card: card,
          onFormalStep: onFormalStep,
          isFormalStepSending: isFormalStepSending,
          isFormalStepSent: isFormalStepSent,
        );
      case MatchStage.unknown:
        return MatchCardStage2(
          card: card,
          onFormalStep: null,
          isFormalStepSending: false,
          isFormalStepSent: false,
        );
    }
  }
}
