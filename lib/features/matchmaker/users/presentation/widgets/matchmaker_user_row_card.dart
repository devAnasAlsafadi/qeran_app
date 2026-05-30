import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/design_system/widgets/qeran_chip.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_user_avatar.dart';
import '../../domain/entities/matchmaker_user_row.dart';

/// One user row: unblurred avatar + full name. The subscribed list adds a
/// gold plan chip and an expiry caption; the other lists show the date the
/// user was assigned to this matchmaker. Tapping opens the profile detail
/// (wired in M2c).
class MatchmakerUserRowCard extends StatelessWidget {
  const MatchmakerUserRowCard({
    super.key,
    required this.row,
    this.onTap,
  });

  final MatchmakerUserRow row;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final caption = _caption(context);
    return QeranCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: QeranSpacing.s12),
      padding: const EdgeInsets.all(QeranSpacing.s12),
      child: Row(
        children: [
          MatchmakerUserAvatar(url: row.profileImageUrl, size: 56),
          QeranSpacing.hs12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  row.fullName,
                  style: QeranTypography.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (row.isSubscribed) ...[
                  QeranSpacing.vs8,
                  QeranChip(
                    label: row.subscriptionPlanName!,
                    variant: QeranChipVariant.interest,
                    compact: true,
                    icon: Icons.workspace_premium_outlined,
                  ),
                ],
                if (caption != null) ...[
                  QeranSpacing.vs4,
                  Text(caption, style: QeranTypography.caption),
                ],
              ],
            ),
          ),
          QeranSpacing.hs8,
          Icon(
            isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            color: QeranColors.inkMuted,
            size: 24,
          ),
        ],
      ),
    );
  }

  /// Subscribed rows surface the subscription expiry; the rest surface the
  /// date the user was assigned. `null` when neither date is available.
  String? _caption(BuildContext context) {
    if (row.isSubscribed && row.subscriptionExpiresAt != null) {
      return '${LocaleKeys.matchmaker_users_subscription_expires.t(context)} '
          '${_formatDate(row.subscriptionExpiresAt!)}';
    }
    if (row.assignedAt != null) {
      return '${LocaleKeys.matchmaker_users_assigned_at.t(context)} '
          '${_formatDate(row.assignedAt!)}';
    }
    return null;
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}/$m/$day';
  }
}
