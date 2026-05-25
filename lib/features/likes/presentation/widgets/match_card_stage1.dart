import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_card.dart';
import 'like_blurred_image.dart';

/// Stage 1 — PhotosExchanged.
///
/// Photo unblurred. Subtitle is the server-localized
/// `formalRequest.statusNameAr / En` when present, else a neutral
/// "photos exchanged, waiting for matchmaker" fallback. Tapping the
/// avatar opens the full gallery sheet.
class MatchCardStage1 extends StatelessWidget {
  final MatchCard card;
  final VoidCallback? onOpenGallery;

  const MatchCardStage1({
    super.key,
    required this.card,
    required this.onOpenGallery,
  });

  @override
  Widget build(BuildContext context) {
    final image = card.primaryImage;
    final formal = card.formalRequest;
    final lang = context.locale.languageCode;
    final formalSubtitle = formal?.localizedStatusName(lang) ?? '';
    final showFormal = formalSubtitle.isNotEmpty;
    return Row(
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
              _Status(
                text: showFormal
                    ? formalSubtitle
                    : LocaleKeys.likes_matches_stage_photos_exchanged_subtitle
                        .t(context),
                icon: showFormal
                    ? Icons.handshake_rounded
                    : Icons.favorite_rounded,
              ),
              if (formal?.updatedByMatchmakerAt != null) ...[
                const SizedBox(height: 4),
                _LastUpdated(at: formal!.updatedByMatchmakerAt!),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppDimens.p12),
        GestureDetector(
          onTap: onOpenGallery,
          child: LikeBlurredImage(
            url: image?.url,
            blur: image?.isBlurred ?? false,
          ),
        ),
      ],
    );
  }
}

class _Status extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Status({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.success),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _LastUpdated extends StatelessWidget {
  final DateTime at;
  const _LastUpdated({required this.at});

  @override
  Widget build(BuildContext context) {
    // Locale-aware short date — relies on easy_localization init to
    // load `intl` symbol tables. Defensive fallback to `YYYY-MM-DD`.
    String formatted;
    try {
      formatted = DateFormat.yMMMd(context.locale.toString()).format(at);
    } catch (_) {
      formatted = '${at.year}-${_pad(at.month)}-${_pad(at.day)}';
    }
    return Text(
      context.tr(
        LocaleKeys.likes_matches_formal_last_updated,
        namedArgs: {'date': formatted},
      ),
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textMuted,
        fontSize: 11,
      ),
    );
  }

  String _pad(int n) => n < 10 ? '0$n' : '$n';
}
