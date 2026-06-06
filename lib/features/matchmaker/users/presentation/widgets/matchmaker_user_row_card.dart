// easy_localization re-exports intl's TextDirection (with .RTL/.LTR), which
// would shadow dart:ui's TextDirection (.rtl) used below — hide it.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/design_system/widgets/qeran_chip.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_user_avatar.dart';
import '../../domain/entities/matchmaker_card_answer.dart';
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
                if (row.answers.isNotEmpty || row.age != null) ...[
                  QeranSpacing.vs4,
                  _AnswersBlock(answers: row.answers, age: row.age),
                ],
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

/// The user's admin-flagged answers (max [_maxAnswers], in the admin-driven
/// order) followed by a standalone age line ("عندي {age} سنة"). Both are
/// dynamic — answers may be empty and age may be null — so the parent only
/// mounts this when at least one is present; any overflow beyond
/// [_maxAnswers] is reached via the full-profile (عرض) screen. Answer text
/// is shown verbatim, Figma-style (no question prefix); the `question` field
/// stays on the entity if context is ever needed.
class _AnswersBlock extends StatelessWidget {
  const _AnswersBlock({required this.answers, this.age});

  final List<MatchmakerCardAnswer> answers;
  final int? age;

  static const int _maxAnswers = 3;

  @override
  Widget build(BuildContext context) {
    final lines = <Widget>[
      for (final a in answers.take(_maxAnswers))
        Text(
          a.answer,
          style: QeranTypography.bodySm,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      if (age != null)
        Text(
          context.tr(
            LocaleKeys.matchmaker_users_age_years,
            namedArgs: {'age': '$age'},
          ),
          style: QeranTypography.bodySm,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) QeranSpacing.vs4,
          lines[i],
        ],
      ],
    );
  }
}
