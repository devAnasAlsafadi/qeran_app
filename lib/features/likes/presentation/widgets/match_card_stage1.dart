import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_card.dart';
import 'like_blurred_image.dart';
import 'match_card_scaffold.dart';
import 'match_matchmaker_status_pill.dart';

/// Stage 1 — PhotosExchanged (photo exchange accepted). Photos are
/// CLEAR (`image.isBlurred == false`) and a formalRequest is active.
/// Tapping the avatar opens the gallery.
/// Surfaces a single [خطوة رسمية عبر الخطّابة] primaryWine CTA.
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
    // The matchmaker's current formal-request status, if the backend supplied
    // one — surfaced as a pill; empty falls back to the static subtitle only.
    final status =
        card.formalRequest?.localizedStatusName(context.locale.languageCode) ??
        '';
    return MatchCardScaffold(
      avatar: GestureDetector(
        onTap: onOpenGallery,
        child: LikeBlurredImage(
          url: image?.url,
          blur: image?.isBlurred ?? false,
        ),
      ),
      name: card.otherUserName,
      statusIcon: Icons.favorite_rounded,
      statusText: LocaleKeys.likes_matches_stage_photos_exchanged_subtitle
          .t(context),
      statusColor: QeranColors.wine,
      primaryLabel: LocaleKeys.likes_matches_formal_step_cta.t(context),
      onPrimaryPressed: onFormalStep,
      primaryLoading: isFormalStepSending,
      primaryTrailingIcon: isFormalStepSent ? Icons.check_rounded : null,
      // Gold primary (decision B); once the formal step is sent it de-emphasises
      // to a neutral "done" chip (still tappable — behaviour unchanged).
      primaryVariant: isFormalStepSent
          ? QeranButtonVariant.neutral
          : QeranButtonVariant.primary,
      footer:
          status.isEmpty ? null : MatchMatchmakerStatusPill(status: status),
    );
  }
}
