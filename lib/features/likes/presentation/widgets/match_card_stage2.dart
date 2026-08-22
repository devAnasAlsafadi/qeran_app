import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_card.dart';
import 'match_card_avatar.dart';
import 'match_card_scaffold.dart';
import 'match_card_sent_action.dart';
import 'match_journey_card.dart';

/// Stage 2 — MatchmakerEngaged (photo exchange rejected). Photos stay
/// BLURRED (`image.isBlurred == true`) and a formalRequest is active.
/// Surfaces a single gold formal-step CTA, which reads as sent — but stays
/// tappable — once the message is posted ([MatchCardSentAction]).
class MatchCardStage2 extends StatelessWidget {
  final MatchCard card;
  final VoidCallback? onFormalStep;
  final bool isFormalStepSending;
  final bool isFormalStepSent;

  const MatchCardStage2({
    super.key,
    required this.card,
    required this.onFormalStep,
    required this.isFormalStepSending,
    required this.isFormalStepSent,
  });

  @override
  Widget build(BuildContext context) {
    final image = card.primaryImage;
    final formal = MatchCardSentAction.resolve(
      isSent: isFormalStepSent,
      cta: LocaleKeys.likes_matches_formal_step_cta.t(context),
      sentLabel: LocaleKeys.likes_matches_formal_step_sent.t(context),
      unsentVariant: QeranButtonVariant.primary,
    );
    return MatchCardScaffold(
      avatar: MatchCardAvatar(
        url: image?.url,
        blur: image?.isBlurred ?? true,
        blurredUrl: image?.blurredUrl,
        blurredThumbnailUrl: image?.blurredThumbnailUrl,
      ),
      name: card.otherUserName,
      statusIcon: Icons.handshake_rounded,
      statusText:
          LocaleKeys.likes_matches_stage_matchmaker_subtitle.t(context),
      statusColor: QeranColors.wine,
      primaryLabel: formal.label,
      onPrimaryPressed: onFormalStep,
      primaryLoading: isFormalStepSending,
      primaryTrailingIcon: formal.trailingIcon,
      primaryVariant: formal.variant,
      footer: MatchJourneyCard(card: card),
    );
  }
}
