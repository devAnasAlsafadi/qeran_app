import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_card.dart';
import '../../domain/entities/match_journey_outcome.dart';
import 'match_card_avatar.dart';
import 'match_card_cancel_action.dart';
import 'match_card_formal_step_section.dart';
import 'match_card_photo_access.dart';
import 'match_card_scaffold.dart';
import 'match_journey_card.dart';

/// Stage 1 — PhotosExchanged (photo exchange accepted). The preview never
/// fetches clear bytes; the explicit reveal action opens the permission-
/// controlled, one-time gallery. A formalRequest may also be active.
/// The formal-step region — CTA, "awaiting their approval", or the
/// accept/decline pair when the other member asked first — is
/// [FormalStepSection]'s, shared with stage 2.
class MatchCardStage1 extends StatelessWidget {
  final MatchCard card;
  final VoidCallback? onOpenGallery;
  final VoidCallback? onFormalStep;
  final bool isFormalStepSending;

  /// Responder callbacks, both taking `pendingFormalStep.id`.
  final void Function(int requestId)? onAcceptFormalStep;
  final void Function(int requestId)? onRejectFormalStep;
  final bool isAcceptingFormalStep;
  final bool isRejectingFormalStep;

  /// Sub-step 5d — end the whole compatibility case from the header. Whether
  /// this card offers a way out at all is [MatchCardCancelAction]'s
  /// four-clause rule, not this widget's: all three stages ask the same
  /// question, and a rule about ending someone's case wants exactly one copy.
  final VoidCallback? onCancelCase;
  final bool isCancelling;

  const MatchCardStage1({
    super.key,
    required this.card,
    required this.onOpenGallery,
    required this.onFormalStep,
    required this.isFormalStepSending,
    this.onAcceptFormalStep,
    this.onRejectFormalStep,
    this.isAcceptingFormalStep = false,
    this.isRejectingFormalStep = false,
    this.onCancelCase,
    this.isCancelling = false,
  });

  @override
  Widget build(BuildContext context) {
    final image = card.primaryImage;
    final photos = MatchCardPhotoAccess.resolve(card, onOpen: onOpenGallery);
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
      avatar: GestureDetector(
        onTap: photos.canOpen ? onOpenGallery : null,
        child: MatchCardAvatar(
          url: image?.url,
          // A stage-1 preview must never fetch/cache the CLEAR bytes; the
          // permission-controlled gallery owns the only reveal path. The
          // server's blurred rendition is a different resource and carries no
          // recoverable detail, so it renders here as a real silhouette.
          blur: true,
          blockImageBytes: true,
          blurredUrl: image?.blurredUrl,
          blurredThumbnailUrl: image?.blurredThumbnailUrl,
        ),
      ),
      name: card.otherUserName,
      statusIcon: formal.statusIconOverride ?? Icons.favorite_rounded,
      // The spent view is reported by `MatchCardPhotosViewed` in the action
      // slot and NOWHERE else. This line used to say it too — one fact in
      // two places, and the two drifted apart in wording the moment either
      // was edited.
      statusText:
          formal.statusTextOverride ??
          LocaleKeys.likes_matches_stage_photos_exchanged_subtitle.t(context),
      statusColor: QeranColors.wine,
      topChip: formal.topChip,
      headerTrailing: MatchCardCancelAction.resolve(
        context,
        card: card,
        onCancel: onCancelCase,
        isCancelling: isCancelling,
      ),
      primaryLabel: formal.primaryLabel,
      onPrimaryPressed: formal.onPrimaryPressed,
      primaryLoading: formal.primaryLoading,
      primaryTrailingIcon: formal.primaryTrailingIcon,
      primaryVariant: QeranButtonVariant.primary,
      primaryOverride: formal.primaryOverride,
      secondaryActions: switch (photos) {
        MatchCardPhotoAccess(canOpen: true) => [
          QeranButton(
            label: LocaleKeys.likes_matches_photo_view_show.t(context),
            onPressed: onOpenGallery,
            variant: QeranButtonVariant.ghost,
            size: QeranButtonSize.xs,
            leadingIcon: Icons.visibility_outlined,
            fullWidth: false,
          ),
        ],
        MatchCardPhotoAccess(wasViewed: true) => const [
          MatchCardPhotosViewed(),
        ],
        _ => null,
      },
      footer: MatchJourneyCard(card: card),
      isEnded: matchJourneyHasEnded(card),
    );
  }
}
