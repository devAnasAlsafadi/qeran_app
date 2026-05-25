import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_card.dart';
import 'like_blurred_image.dart';

/// Stage 2 — MatchmakerEngaged. Photos remain blurred. CTA routes the
/// user to the matchmaker conversation when `conversationId` is set,
/// else surfaces a localized "the matchmaker will contact you soon"
/// message via [onContactMatchmaker].
class MatchCardStage2 extends StatelessWidget {
  final MatchCard card;
  final VoidCallback? onContactMatchmaker;

  const MatchCardStage2({
    super.key,
    required this.card,
    required this.onContactMatchmaker,
  });

  @override
  Widget build(BuildContext context) {
    final image = card.primaryImage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.otherUserName,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimens.p8),
                  Row(
                    children: [
                      const Icon(
                        Icons.handshake_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          LocaleKeys.likes_matches_stage_matchmaker_subtitle
                              .t(context),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimens.p12),
            LikeBlurredImage(url: image?.url, blur: true),
          ],
        ),
        const SizedBox(height: AppDimens.p16),
        _ContactCta(onTap: onContactMatchmaker),
      ],
    );
  }
}

class _ContactCta extends StatelessWidget {
  final VoidCallback? onTap;
  const _ContactCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: disabled ? null : onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: disabled ? 0.3 : 1.0),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          LocaleKeys.likes_matches_stage_matchmaker_cta.t(context),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
