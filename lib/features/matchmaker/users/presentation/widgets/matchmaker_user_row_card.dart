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
import '../../domain/entities/matchmaker_users_list.dart';
import 'matchmaker_card_action_row.dart';
import 'matchmaker_card_answers_block.dart';
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
    this.onMessage,
    this.onNotes,
    this.onView,
    this.loadingAction,
  });

  final MatchmakerUserRow row;

  /// Which of the three lists this card belongs to — selects the button set.
  final MatchmakerUsersList list;

  /// Called after an on-card action mutates the user (approve/reject) so the
  /// list can refresh and drop the row. Null on lists without such actions.
  final VoidCallback? onMutated;

  /// Called when مراسلة is tapped — the list resolves + opens the chat (M3c).
  /// Null on contexts without messaging.
  final VoidCallback? onMessage;

  /// Called when ملاحظات is tapped — the list opens the notes sheet (M3d).
  /// Null on contexts without notes.
  final VoidCallback? onNotes;

  /// Called when عرض is tapped — the list opens the (view-only) profile (M3e).
  /// Null on contexts without a profile view.
  final VoidCallback? onView;

  /// Which action's button shows a loader, driven by the list's open-chat
  /// state. Null when idle.
  final MatchmakerCardAction? loadingAction;

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
                      MatchmakerCardAnswersBlock(
                        answers: row.answers,
                        age: row.age,
                      ),
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
            loadingAction: loadingAction,
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
        onMessage?.call();
      case MatchmakerCardAction.notes:
        onNotes?.call();
      case MatchmakerCardAction.view:
        onView?.call();
      case MatchmakerCardAction.interests:
        break; // wired in M3f
    }
  }

  /// موافقة → confirm sheet (approve / reject-with-reason). On success the
  /// sheet pops `true`; we bubble it up via [onMutated] so the list refreshes.
  Future<void> _openReviewSheet(BuildContext context) async {
    final mutated = await showMatchmakerReviewSheet(
      context,
      userId: row.userId,
      // Pending rows carry hasProfileImage; offer request-photo when absent.
      hasNoImage: row.hasProfileImage == false,
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
