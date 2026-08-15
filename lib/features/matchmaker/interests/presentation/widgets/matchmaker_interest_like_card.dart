import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_chip.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_fact_chips.dart';
import '../../../../likes/presentation/widgets/like_card_countdown_chip.dart';
import '../../domain/entities/matchmaker_interest_enums.dart';
import '../../domain/entities/matchmaker_interest_like.dart';
import 'matchmaker_interest_card.dart';

/// Read-only like row (used for both pending and archived likes — the status
/// chip conveys which). Reuses [MatchmakerInterestCard] as a thin visual adapter.
class MatchmakerInterestLikeCard extends StatelessWidget {
  const MatchmakerInterestLikeCard({super.key, required this.like});

  final MatchmakerInterestLike like;

  @override
  Widget build(BuildContext context) {
    final locked = like.isLocked;
    final spec = _statusSpec(like.status);

    return MatchmakerInterestCard(
      imageUrl: like.image?.url,
      name: like.name,
      locked: locked,
      onTap: locked
          ? null
          : () => NavigationManager.navigateTo(
              context,
              RouteNames.matchmakerUserProfile,
              arguments: like.otherUserId,
            ),
      chips: [
        if (like.status == MatchmakerInterestLikeStatus.pending &&
            (like.expiresAt != null || like.remainingSeconds != null))
          LikeCountdownChip(
            expiresAt: like.expiresAt,
            initialSeconds: like.remainingSeconds,
          ),
        if (spec != null)
          QeranChip(
            label: spec.labelKey.t(context),
            variant: QeranChipVariant.status,
            statusColor: spec.color,
            compact: true,
          ),
      ],
      facts: like.answers.isNotEmpty || like.age != null
          ? MatchmakerFactChips(
              facts: [for (final a in like.answers) a.answer],
              age: like.age,
              ageAsChip: true,
            )
          : null,
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
