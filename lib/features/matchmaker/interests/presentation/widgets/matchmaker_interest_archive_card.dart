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
import '../../domain/entities/matchmaker_interest_archive_item.dart';
import '../../domain/entities/matchmaker_interest_enums.dart';

/// Read-only archived item — a closed like or photo-exchange. Shows the other
/// party + a small [type] indicator + a status chip whose label is the backend
/// `status` text (falling back to the [reason] label) and whose colour comes
/// from the reason. Archived items are historical: never redacted, always
/// tappable → the other party's profile.
class MatchmakerInterestArchiveCard extends StatelessWidget {
  const MatchmakerInterestArchiveCard({super.key, required this.item});

  final MatchmakerInterestArchiveItem item;

  @override
  Widget build(BuildContext context) {
    final reason = _reasonSpec(item.reason);
    final type = _typeSpec(item.type);
    final statusLabel =
        item.status.isNotEmpty ? item.status : reason.fallbackKey?.t(context);
    return QeranCard(
      margin: const EdgeInsets.only(bottom: QeranSpacing.s12),
      padding: const EdgeInsets.all(QeranSpacing.s12),
      onTap: () => NavigationManager.navigateTo(
        context,
        RouteNames.matchmakerUserProfile,
        arguments: item.otherUserId,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LikeBlurredImage(url: item.image?.url, blur: false, size: 56),
          QeranSpacing.hs12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        style: QeranTypography.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (type != null) ...[
                      QeranSpacing.hs8,
                      QeranChip(
                        label: type.labelKey.t(context),
                        variant: QeranChipVariant.meta,
                        icon: type.icon,
                        compact: true,
                      ),
                    ],
                  ],
                ),
                if (item.answers.isNotEmpty) ...[
                  QeranSpacing.vs4,
                  MatchmakerCardAnswersBlock(answers: item.answers),
                ],
                if (statusLabel != null) ...[
                  QeranSpacing.vs8,
                  QeranChip(
                    label: statusLabel,
                    variant: QeranChipVariant.status,
                    statusColor: reason.color,
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
