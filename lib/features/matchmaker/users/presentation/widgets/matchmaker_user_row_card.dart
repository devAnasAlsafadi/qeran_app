import 'package:easy_localization/easy_localization.dart';
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
import '../../domain/entities/matchmaker_users_list.dart';
import 'matchmaker_card_action_row.dart';
import 'matchmaker_review_action_sheet.dart';

/// One user row: unblurred avatar + name + flagged answers/age, with a
/// per-list [MatchmakerCardActionRow] beneath. The card body itself is NOT
/// tappable — every action lives on its own button (scaffolded in M3a,
/// wired in M3b–f). The subscribed list also shows a gold plan chip + the
/// subscription-expiry line.
class MatchmakerUserRowCard extends StatelessWidget {
  const MatchmakerUserRowCard({
    super.key,
    required this.row,
    required this.list,
    this.onMutated,
  });

  final MatchmakerUserRow row;

  /// Which of the three lists this card belongs to — selects the button set.
  final MatchmakerUsersList list;

  /// Called after an on-card action mutates the user (approve/reject) so the
  /// list can refresh and drop the row. Null on lists without such actions.
  final VoidCallback? onMutated;

  @override
  Widget build(BuildContext context) {
    final caption = _caption(context);
    return QeranCard(
      margin: const EdgeInsets.only(bottom: QeranSpacing.s12),
      padding: const EdgeInsets.all(QeranSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
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
            ],
          ),
          QeranSpacing.vs12,
          Container(height: 1, color: QeranColors.divider),
          QeranSpacing.vs12,
          MatchmakerCardActionRow(
            list: list,
            onAction: (action) => _onAction(context, action),
          ),
        ],
      ),
    );
  }

  void _onAction(BuildContext context, MatchmakerCardAction action) {
    switch (action) {
      case MatchmakerCardAction.approve:
        _openReviewSheet(context);
      case MatchmakerCardAction.message:
      case MatchmakerCardAction.view:
      case MatchmakerCardAction.notes:
      case MatchmakerCardAction.interests:
        break; // wired in M3c–f
    }
  }

  /// موافقة → confirm sheet (approve / reject-with-reason). On success the
  /// sheet pops `true`; we bubble it up via [onMutated] so the list refreshes.
  Future<void> _openReviewSheet(BuildContext context) async {
    final mutated = await showMatchmakerReviewSheet(
      context,
      userId: row.userId,
    );
    if (mutated == true) onMutated?.call();
  }

  /// Subscribed rows surface the subscription expiry under the plan chip.
  /// The M3a redesign dropped the assignedAt caption (the old "date in the
  /// corner"); `null` on the non-subscribed lists. Expiry is kept here since
  /// it pairs with the plan chip.
  String? _caption(BuildContext context) {
    if (row.isSubscribed && row.subscriptionExpiresAt != null) {
      return '${LocaleKeys.matchmaker_users_subscription_expires.t(context)} '
          '${_formatDate(row.subscriptionExpiresAt!)}';
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
