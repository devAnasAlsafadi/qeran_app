import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_card.dart';
import 'like_blurred_image.dart';
import 'match_card_scaffold.dart';

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
    );
  }
}
