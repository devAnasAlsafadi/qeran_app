import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/features/likes/presentation/widgets/like_blurred_image.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/shared_profile.dart';

/// MVP card rendered inside a chat bubble for `[profile:guid]`
/// messages.
///
/// Per backend Q8 the chat-side `sharedProfile` ships a lightweight
/// snapshot: image + name + optional age + optional matching score.
/// `placements` is always `[]` on this surface, so we deliberately
/// don't render any detail rows. Per design, **not tappable** in MVP
/// — opening the full profile would require a separate fetch we
/// haven't built yet.
///
/// The two variants (outgoing vs incoming bubble) only differ in
/// background tint + score-chip accent so the speaker is unambiguous;
/// the layout stays identical so RTL/LTR is automatically correct
/// via `AlignmentDirectional` everywhere.
class SharedProfileMessageCard extends StatelessWidget {
  final SharedProfile profile;
  final bool isMine;

  /// Tap callback wired by [ChatMessageBubble] — opens the reusable
  /// [FullProfileDetailsScreen] with this profile as a seed. Null
  /// disables tap (kept for legacy callers / tests).
  final VoidCallback? onTap;

  const SharedProfileMessageCard({
    super.key,
    required this.profile,
    required this.isMine,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = profile.primaryImage;
    final hasScore = profile.matchingScore > 0;
    // Inner card sits inside the bubble shell. Tints are subtle —
    // outgoing reverses to cream-on-burgundy, incoming stays
    // white-on-soft-gold-accent.
    final innerBg = isMine
        ? AppColors.white.withValues(alpha: 0.10)
        : AppColors.primary.withValues(alpha: 0.04);
    final accent = isMine ? AppColors.white : AppColors.primary;
    final titleColor = isMine ? AppColors.white : AppColors.textPrimary;
    final subTitleColor = isMine
        ? AppColors.white.withValues(alpha: 0.85)
        : AppColors.textSecondary;
    final body = Container(
      width: 240,
      padding: const EdgeInsets.all(AppDimens.p12),
      decoration: BoxDecoration(
        color: innerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              LikeBlurredImage(
                url: image?.url,
                blur: image?.isBlurred ?? true,
                size: 56,
              ),
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _nameAndAge(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasScore) ...[
                      const SizedBox(height: 6),
                      _ScoreChip(
                        percent: profile.matchingScore,
                        accent: accent,
                        textColor: titleColor,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.p8),
          Text(
            _sharedByLabel(context),
            style: AppTextStyles.caption.copyWith(
              color: subTitleColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
    if (onTap == null) return body;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: body,
      ),
    );
  }

  String _nameAndAge() {
    final age = profile.age;
    if (age == null) return profile.name;
    return '${profile.name} · $age';
  }

  String _sharedByLabel(BuildContext context) {
    if (isMine) {
      return LocaleKeys.chat_shared_profile_shared_by_me.t(context);
    }
    // For matchmaker-shared we don't yet thread the matchmaker name
    // here — show the generic label until we wire that through.
    return LocaleKeys.chat_shared_profile_shared_by_matchmaker.t(context);
  }
}

class _ScoreChip extends StatelessWidget {
  final double percent;
  final Color accent;
  final Color textColor;
  const _ScoreChip({
    required this.percent,
    required this.accent,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // Server may ship a fractional percent (78.5). Round to nearest
    // whole percent for display.
    final rounded = percent.round();
    final label = context.tr(
      LocaleKeys.chat_shared_profile_score_label,
      namedArgs: {'percent': '$rounded'},
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
