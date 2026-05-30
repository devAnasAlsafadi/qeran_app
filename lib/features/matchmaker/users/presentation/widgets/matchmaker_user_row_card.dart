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

/// One user row: unblurred avatar, name, gender · age, and — for the
/// subscribed list — a gold subscription chip plus an expiry caption.
/// Tapping opens the profile detail (wired in M2c).
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
                  row.name,
                  style: QeranTypography.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                QeranSpacing.vs8,
                Wrap(
                  spacing: QeranSpacing.s8,
                  runSpacing: QeranSpacing.s6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    QeranChip(
                      label: _genderAge(context),
                      variant: QeranChipVariant.meta,
                      compact: true,
                    ),
                    if (row.isSubscribed)
                      QeranChip(
                        label: row.subscriptionPlanName!,
                        variant: QeranChipVariant.interest,
                        compact: true,
                        icon: Icons.workspace_premium_outlined,
                      ),
                  ],
                ),
                if (row.isSubscribed && row.subscriptionExpiresAt != null) ...[
                  QeranSpacing.vs4,
                  Text(
                    '${LocaleKeys.matchmaker_users_subscription_expires.t(context)} '
                    '${_formatDate(row.subscriptionExpiresAt!)}',
                    style: QeranTypography.caption,
                  ),
                ],
              ],
            ),
          ),
          QeranSpacing.hs8,
          Icon(
            isRtl
                ? Icons.chevron_left_rounded
                : Icons.chevron_right_rounded,
            color: QeranColors.inkMuted,
            size: 24,
          ),
        ],
      ),
    );
  }

  String _genderAge(BuildContext context) {
    final g = _genderLabel(context, row.gender);
    if (row.age == null) return g;
    return '$g · ${row.age}';
  }

  String _genderLabel(BuildContext context, String raw) =>
      switch (raw.toLowerCase()) {
        'male' => LocaleKeys.matchmaker_user_male.t(context),
        'female' => LocaleKeys.matchmaker_user_female.t(context),
        _ => raw,
      };

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}/$m/$day';
  }
}
