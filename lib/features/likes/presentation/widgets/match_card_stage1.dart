import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_card.dart';
import 'match_card_avatar.dart';
import 'match_card_scaffold.dart';
import 'match_card_sent_action.dart';
import 'match_matchmaker_status_pill.dart';

/// Stage 1 — PhotosExchanged (photo exchange accepted). The preview never
/// fetches clear bytes; the explicit reveal action opens the permission-
/// controlled, one-time gallery. A formalRequest may also be active.
/// Surfaces a single gold formal-step CTA, which reads as sent — but stays
/// tappable — once the message is posted ([MatchCardSentAction]).
class MatchCardStage1 extends StatelessWidget {
  final MatchCard card;
  final VoidCallback? onOpenGallery;
  final VoidCallback? onFormalStep;
  final bool isFormalStepSending;
  final bool isFormalStepSent;

  const MatchCardStage1({
    super.key,
    required this.card,
    required this.onOpenGallery,
    required this.onFormalStep,
    required this.isFormalStepSending,
    required this.isFormalStepSent,
  });

  @override
  Widget build(BuildContext context) {
    final image = card.primaryImage;
    final isConsumed =
        card.images.isNotEmpty && card.images.every((image) => image.isBlurred);
    final canOpenPhotos =
        card.images.any((candidate) => !candidate.isBlurred) &&
        onOpenGallery != null;
    // The matchmaker's current formal-request status, if the backend supplied
    // one — surfaced as a pill; empty falls back to the static subtitle only.
    final status =
        card.formalRequest?.localizedStatusName(context.locale.languageCode) ??
        '';
    final formal = MatchCardSentAction.resolve(
      isSent: isFormalStepSent,
      cta: LocaleKeys.likes_matches_formal_step_cta.t(context),
      sentLabel: LocaleKeys.likes_matches_formal_step_sent.t(context),
      unsentVariant: QeranButtonVariant.primary,
    );
    return MatchCardScaffold(
      avatar: GestureDetector(
        onTap: canOpenPhotos ? onOpenGallery : null,
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
      statusIcon: Icons.favorite_rounded,
      statusText:
          (isConsumed
                  ? LocaleKeys.likes_matches_photo_view_consumed
                  : LocaleKeys.likes_matches_stage_photos_exchanged_subtitle)
              .t(context),
      statusColor: QeranColors.wine,
      primaryLabel: formal.label,
      onPrimaryPressed: onFormalStep,
      primaryLoading: isFormalStepSending,
      primaryTrailingIcon: formal.trailingIcon,
      primaryVariant: formal.variant,
      secondaryActions: canOpenPhotos
          ? [
              QeranButton(
                label: LocaleKeys.likes_matches_photo_view_show.t(context),
                onPressed: onOpenGallery,
                variant: QeranButtonVariant.ghost,
                size: QeranButtonSize.xs,
                leadingIcon: Icons.visibility_outlined,
                fullWidth: false,
              ),
            ]
          : null,
      footer: status.isEmpty ? null : MatchMatchmakerStatusPill(status: status),
    );
  }
}
