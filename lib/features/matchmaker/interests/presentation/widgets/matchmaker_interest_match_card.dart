import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_chip.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../../features/likes/presentation/widgets/like_card_countdown_chip.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_fact_chips.dart';
import '../../domain/entities/matchmaker_interest_enums.dart';
import '../../domain/entities/matchmaker_interest_formal_request.dart';
import '../../domain/entities/matchmaker_interest_match.dart';
import 'matchmaker_interest_card.dart';

/// Read-only active-match card — the gold-accented tier. Reuses
/// [MatchmakerInterestCard] as a thin visual adapter.
class MatchmakerInterestMatchCard extends StatelessWidget {
  const MatchmakerInterestMatchCard({super.key, required this.match});

  final MatchmakerInterestMatch match;

  @override
  Widget build(BuildContext context) {
    final locked = match.isLocked;
    final spec = _stageSpec(match.stage);
    final formalLabel = _formalLabel(context, match.formalRequest);
    final countdown = _countdown();

    return MatchmakerInterestCard(
      imageUrl: match.primaryImage?.url,
      name: match.name,
      locked: locked,
      onTap: locked
          ? null
          : () => NavigationManager.navigateTo(
              context,
              RouteNames.matchmakerUserProfile,
              arguments: match.otherUserId,
            ),
      chips: [
        // Leads the row while it is running — a deadline is the most
        // perishable thing on the card. Shown ONLY for a photo exchange that
        // is still open; an accepted, rejected or lapsed one keeps its stage
        // chip and no clock. Same chip the like cards on the other two tabs
        // use, so one screen speaks with one voice.
        ?countdown,
        QeranChip(
          label: spec.labelKey.t(context),
          variant: QeranChipVariant.status,
          statusColor: spec.color,
          icon: spec.icon,
          compact: true,
        ),
        if (formalLabel != null)
          QeranChip(
            label: formalLabel,
            variant: QeranChipVariant.interest,
            icon: Icons.verified_outlined,
            compact: true,
          ),
      ],
      facts: match.answers.isNotEmpty || match.age != null
          ? MatchmakerFactChips(
              facts: [for (final a in match.answers) a.answer],
              age: match.age,
              ageAsChip: true,
            )
          : null,
    );
  }

  /// The live photo-exchange countdown, or null when there is nothing running
  /// to count. `isAwaitingResponse` covers all three ways that happens: no
  /// exchange, a resolved one, and a lapsed one whose block the server still
  /// returns.
  Widget? _countdown() {
    final exchange = match.pendingPhotoExchange;
    if (exchange == null || !exchange.isAwaitingResponse) return null;
    if (exchange.expiresAt == null) return null;
    return LikeCountdownChip(
      expiresAt: exchange.expiresAt,
      initialSeconds: exchange.remainingSeconds,
    );
  }
}

/// Backend formal-status text, locale-aware (Arabic default, English when the
/// app is in English and a value is provided). `null` when there's no formal
/// request yet.
String? _formalLabel(
  BuildContext context,
  MatchmakerInterestFormalRequest? formal,
) {
  if (formal == null) return null;
  final ar = formal.statusNameAr;
  final en = formal.statusNameEn;
  final isArabic = context.locale.languageCode == 'ar';
  final label = isArabic ? ar : (en.isNotEmpty ? en : ar);
  return label.isEmpty ? null : label;
}

({String labelKey, IconData icon, Color color}) _stageSpec(
  MatchmakerInterestMatchStage stage,
) {
  return switch (stage) {
    MatchmakerInterestMatchStage.waitingForPhotoExchange => (
      labelKey: LocaleKeys.matchmaker_interests_match_stage_waiting,
      icon: Icons.photo_camera_outlined,
      color: QeranColors.wine,
    ),
    MatchmakerInterestMatchStage.photosExchanged => (
      labelKey: LocaleKeys.matchmaker_interests_match_stage_exchanged,
      icon: Icons.photo_library_outlined,
      color: QeranColors.gold,
    ),
    MatchmakerInterestMatchStage.matchmakerEngaged => (
      labelKey: LocaleKeys.matchmaker_interests_match_stage_engaged,
      icon: Icons.handshake_outlined,
      color: QeranColors.gold,
    ),
    MatchmakerInterestMatchStage.unknown => (
      labelKey: LocaleKeys.matchmaker_interests_match_stage_waiting,
      icon: Icons.favorite_border_rounded,
      color: QeranColors.inkMuted,
    ),
  };
}
