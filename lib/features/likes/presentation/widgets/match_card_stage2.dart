import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_card.dart';
import 'match_card_avatar.dart';
import 'match_card_formal_step_section.dart';
import 'match_card_scaffold.dart';
import 'match_journey_card.dart';

/// Stage 2 — MatchmakerEngaged (photo exchange rejected). Photos stay
/// BLURRED (`image.isBlurred == true`) and a formalRequest is active.
/// The formal-step region — CTA, "awaiting their approval", or the
/// accept/decline pair when the other member asked first — is
/// [FormalStepSection]'s, shared with stage 2.
class MatchCardStage2 extends StatelessWidget {
  final MatchCard card;
  final VoidCallback? onFormalStep;
  final bool isFormalStepSending;

  /// Responder callbacks, both taking `pendingFormalStep.id`.
  final void Function(int requestId)? onAcceptFormalStep;
  final void Function(int requestId)? onRejectFormalStep;
  final bool isAcceptingFormalStep;
  final bool isRejectingFormalStep;

  const MatchCardStage2({
    super.key,
    required this.card,
    required this.onFormalStep,
    required this.isFormalStepSending,
    this.onAcceptFormalStep,
    this.onRejectFormalStep,
    this.isAcceptingFormalStep = false,
    this.isRejectingFormalStep = false,
  });

  @override
  Widget build(BuildContext context) {
    final image = card.primaryImage;
    final formal = FormalStepSection.resolve(
      context,
      card: card,
      onFormalStep: onFormalStep,
      isSending: isFormalStepSending,
      onAccept: onAcceptFormalStep,
      onReject: onRejectFormalStep,
      isAccepting: isAcceptingFormalStep,
      isRejecting: isRejectingFormalStep,
    );
    return MatchCardScaffold(
      avatar: MatchCardAvatar(
        url: image?.url,
        blur: image?.isBlurred ?? true,
        blurredUrl: image?.blurredUrl,
        blurredThumbnailUrl: image?.blurredThumbnailUrl,
      ),
      name: card.otherUserName,
      statusIcon: formal.statusIconOverride ?? Icons.handshake_rounded,
      statusText:
          formal.statusTextOverride ??
          LocaleKeys.likes_matches_stage_matchmaker_subtitle.t(context),
      statusColor: QeranColors.wine,
      topChip: formal.topChip,
      primaryLabel: formal.primaryLabel,
      onPrimaryPressed: formal.onPrimaryPressed,
      primaryLoading: formal.primaryLoading,
      primaryTrailingIcon: formal.primaryTrailingIcon,
      primaryVariant: QeranButtonVariant.primary,
      primaryOverride: formal.primaryOverride,
      primaryHelperText: formal.helperText,
      footer: MatchJourneyCard(card: card),
    );
  }
}
