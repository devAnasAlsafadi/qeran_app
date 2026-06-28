import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/design_system/widgets/qeran_chip.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../../likes/presentation/widgets/like_blurred_image.dart';
import '../../../users/presentation/widgets/matchmaker_card_answers_block.dart';
import '../../domain/entities/matchmaker_interest_enums.dart';
import '../../domain/entities/matchmaker_interest_like.dart';

/// Read-only like row (used for both pending and archived likes — the status
/// chip conveys which). No actions, no countdown. When [MatchmakerInterestLike.
/// isLocked] the other party is redacted (blurred image, hidden name + answers)
/// with a neutral lock — never a subscription CTA, since the matchmaker isn't
/// the buyer; a locked card is not tappable.
class MatchmakerInterestLikeCard extends StatelessWidget {
  const MatchmakerInterestLikeCard({super.key, required this.like});

  final MatchmakerInterestLike like;

  @override
  Widget build(BuildContext context) {
    final locked = like.isLocked;
    final spec = _statusSpec(like.status);
    return QeranCard(
      margin: const EdgeInsets.only(bottom: QeranSpacing.s12),
      padding: const EdgeInsets.all(QeranSpacing.s12),
      onTap: locked
          ? null
          : () => NavigationManager.navigateTo(
                context,
                RouteNames.matchmakerUserProfile,
                arguments: like.otherUserId,
              ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LikeBlurredImage(url: like.image?.url, blur: locked, size: 56),
          QeranSpacing.hs12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _NameLine(
                  name: locked
                      ? LocaleKeys.matchmaker_interests_locked_name.t(context)
                      : like.name,
                  locked: locked,
                ),
                if (!locked && like.answers.isNotEmpty) ...[
                  QeranSpacing.vs4,
                  MatchmakerCardAnswersBlock(answers: like.answers),
                ],
                if (spec != null) ...[
                  QeranSpacing.vs8,
                  QeranChip(
                    label: spec.labelKey.t(context),
                    variant: QeranChipVariant.status,
                    statusColor: spec.color,
                    compact: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Name + a lock glyph when the identity is redacted.
class _NameLine extends StatelessWidget {
  const _NameLine({required this.name, required this.locked});

  final String name;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            name,
            style: QeranTypography.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (locked) ...[
          QeranSpacing.hs4,
          const Icon(Icons.lock_outline_rounded, size: 14, color: QeranColors.inkMuted),
        ],
      ],
    );
  }
}

({String labelKey, Color color})? _statusSpec(
  MatchmakerInterestLikeStatus status,
) {
  return switch (status) {
    MatchmakerInterestLikeStatus.pending => (
        labelKey: LocaleKeys.matchmaker_interests_like_status_pending,
        color: QeranColors.wine,
      ),
    MatchmakerInterestLikeStatus.accepted => (
        labelKey: LocaleKeys.matchmaker_interests_like_status_accepted,
        color: QeranColors.gold,
      ),
    MatchmakerInterestLikeStatus.rejected => (
        labelKey: LocaleKeys.matchmaker_interests_like_status_rejected,
        color: QeranColors.danger,
      ),
    MatchmakerInterestLikeStatus.expired => (
        labelKey: LocaleKeys.matchmaker_interests_like_status_expired,
        color: QeranColors.inkMuted,
      ),
    MatchmakerInterestLikeStatus.unknown => null,
  };
}
