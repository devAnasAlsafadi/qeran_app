import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_chip.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_fact_chips.dart';
import '../../domain/entities/matchmaker_interest_archive_item.dart';
import '../../domain/entities/matchmaker_interest_enums.dart';
import 'matchmaker_interest_card.dart';

/// Read-only archived item — a closed like or photo-exchange. Reuses
/// [MatchmakerInterestCard] as a thin visual adapter, with archived: true for
/// the flat canvas background treatment.
class MatchmakerInterestArchiveCard extends StatelessWidget {
  const MatchmakerInterestArchiveCard({super.key, required this.item});

  final MatchmakerInterestArchiveItem item;

  @override
  Widget build(BuildContext context) {
    final reason = _reasonSpec(item.reason);
    final type = _typeSpec(item.type);
    // Prefer the backend's pre-translated, locale-aware label; fall back to the
    // raw status (old records) then the reason label.
    final translated =
        item.statusName(isArabic: context.locale.languageCode == 'ar');
    final statusLabel = translated.isNotEmpty
        ? translated
        : (item.status.isNotEmpty ? item.status : reason.fallbackKey?.t(context));

    return MatchmakerInterestCard(
      imageUrl: item.image?.url,
      name: item.name,
      locked: false,
      archived: true,
      onTap: () => NavigationManager.navigateTo(
        context,
        RouteNames.matchmakerUserProfile,
        arguments: item.otherUserId,
      ),
      chips: [
        if (type != null)
          QeranChip(
            label: type.labelKey.t(context),
            variant: QeranChipVariant.meta,
            icon: type.icon,
            compact: true,
          ),
        if (statusLabel != null)
          QeranChip(
            label: statusLabel,
            variant: QeranChipVariant.status,
            statusColor: reason.color,
            compact: true,
          ),
      ],
      facts: item.answers.isNotEmpty
          // No age on an archived row — the DTO carries none.
          ? MatchmakerFactChips(
              facts: [for (final a in item.answers) a.answer],
              ageAsChip: true,
            )
          : null,
    );
  }
}

({String labelKey, IconData icon})? _typeSpec(MatchmakerArchiveType type) {
  return switch (type) {
    MatchmakerArchiveType.like => (
        labelKey: LocaleKeys.matchmaker_interests_archive_type_like,
        icon: Icons.favorite_border_rounded,
      ),
    MatchmakerArchiveType.photoExchange => (
        labelKey: LocaleKeys.matchmaker_interests_archive_type_photo_exchange,
        icon: Icons.photo_camera_outlined,
      ),
    MatchmakerArchiveType.unknown => null,
  };
}

({Color color, String? fallbackKey}) _reasonSpec(MatchmakerArchiveReason r) {
  return switch (r) {
    MatchmakerArchiveReason.rejected => (
        color: QeranColors.danger,
        fallbackKey: LocaleKeys.matchmaker_interests_archive_reason_rejected,
      ),
    MatchmakerArchiveReason.expired => (
        color: QeranColors.inkMuted,
        fallbackKey: LocaleKeys.matchmaker_interests_archive_reason_expired,
      ),
    MatchmakerArchiveReason.unknown => (
        color: QeranColors.inkMuted,
        fallbackKey: null,
      ),
  };
}
