import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/design_system/widgets/qeran_chip.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_card_action_bar.dart';
import '../../../shared/presentation/widgets/matchmaker_fact_chips.dart';
import '../../../shared/presentation/widgets/matchmaker_user_avatar.dart';
import '../../domain/entities/matchmaker_user_row.dart';
import '../../domain/entities/matchmaker_users_list.dart';
import 'matchmaker_review_action_sheet.dart';

/// The action a card button triggers. The card maps each to its handler; only
/// [message] is ever shown as `loading` (while its conversation resolves).
enum MatchmakerCardAction { approve, message, view, notes, interests }

/// One user row — a 52px avatar (photo → wine+gold monogram fallback), name,
/// ≤3 fact chips + age, and a per-list action bar (gold primary + icon-only
/// wine-06 secondaries). Subscribed rows add a gold plan chip and a quiet
/// top-end expiry. The card body is NOT tappable — every action is a button.
class MatchmakerUserRowCard extends StatelessWidget {
  const MatchmakerUserRowCard({
    super.key,
    required this.row,
    required this.list,
    this.showPlanChip = true,
    this.onMutated,
    this.onMessage,
    this.onNotes,
    this.onView,
    this.onInterests,
    this.loadingAction,
  });

  final MatchmakerUserRow row;

  /// Which of the three lists this card belongs to — selects the button set.
  final MatchmakerUsersList list;

  /// Whether to render the plan chip on a subscribed row. False when the rail
  /// has filtered to one plan (then it's redundant). Only the subscribed list
  /// ever passes false.
  final bool showPlanChip;

  /// Called after an on-card action mutates the user (approve/reject) so the
  /// list can refresh and drop the row.
  final VoidCallback? onMutated;

  /// مراسلة — the list resolves + opens the chat (shows the loader meanwhile).
  final VoidCallback? onMessage;

  /// ملاحظات — the list opens the notes sheet.
  final VoidCallback? onNotes;

  /// عرض — the list opens the (view-only) profile.
  final VoidCallback? onView;

  /// الإهتمامات — the interests mirror (subscribed list only).
  final VoidCallback? onInterests;

  /// Which action's button shows a loader (only ever [MatchmakerCardAction.message]).
  final MatchmakerCardAction? loadingAction;

  static const double _avatarSize = 52;

  @override
  Widget build(BuildContext context) {
    final expiry = _expiryLabel(context);
    final hasFacts = row.answers.isNotEmpty || row.age != null;
    final hasPlanChip = row.isSubscribed && showPlanChip;
    // When the name column carries nothing beneath the name, centre the row
    // against the avatar and show a quiet placeholder instead of a gap.
    final hasDetails = hasFacts || hasPlanChip;

    return QeranCard(
      margin: const EdgeInsets.only(bottom: QeranSpacing.s12),
      padding: const EdgeInsets.all(QeranSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: hasDetails
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              MatchmakerUserAvatar(
                url: row.profileImageUrl,
                size: _avatarSize,
                monogramName: row.fullName,
              ),
              QeranSpacing.hs12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      row.fullName,
                      style: QeranTypography.subtitle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasFacts) ...[
                      QeranSpacing.vs4,
                      MatchmakerFactChips(
                        facts: [for (final a in row.answers) a.answer],
                        age: row.age,
                        ageAsChip: true,
                      ),
                    ],
                    if (hasPlanChip) ...[
                      QeranSpacing.vs8,
                      QeranChip(
                        label: row.subscriptionPlanName!,
                        variant: QeranChipVariant.plan,
                        compact: true,
                        icon: Icons.workspace_premium_outlined,
                      ),
                    ],
                    if (!hasDetails) ...[
                      QeranSpacing.vs4,
                      Text(
                        LocaleKeys.matchmaker_users_no_details_yet.t(context),
                        style: QeranTypography.bodySm.copyWith(
                          color: QeranColors.inkFaint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Quiet expiry in the top-END corner — mirrors automatically.
              if (expiry != null) ...[
                QeranSpacing.hs8,
                Text(
                  expiry,
                  style: QeranTypography.caption.copyWith(
                    color: QeranColors.inkFaint,
                  ),
                ),
              ],
            ],
          ),
          QeranSpacing.vs12,
          MatchmakerCardActionBar(
            primary: _primaryFor(context),
            secondaries: _secondariesFor(context),
          ),
        ],
      ),
    );
  }

  MatchmakerPrimaryAction _primaryFor(BuildContext context) {
    // Pending → موافقة; the approved lists → عرض (the most-used action).
    if (list == MatchmakerUsersList.pending) {
      return MatchmakerPrimaryAction(
        label: LocaleKeys.matchmaker_users_action_approve.t(context),
        icon: Icons.check_circle_outline_rounded,
        onTap: () => _openReviewSheet(context),
      );
    }
    return MatchmakerPrimaryAction(
      label: LocaleKeys.matchmaker_users_action_view.t(context),
      icon: Icons.visibility_outlined,
      onTap: () => onView?.call(),
    );
  }

  List<MatchmakerSecondaryAction> _secondariesFor(BuildContext context) {
    final message = MatchmakerSecondaryAction(
      icon: Icons.chat_bubble_outline_rounded,
      tooltip: LocaleKeys.matchmaker_users_action_message.t(context),
      onTap: () => onMessage?.call(),
      loading: loadingAction == MatchmakerCardAction.message,
    );
    final notes = MatchmakerSecondaryAction(
      icon: Icons.note_alt_outlined,
      tooltip: LocaleKeys.matchmaker_users_action_notes.t(context),
      onTap: () => onNotes?.call(),
    );
    final view = MatchmakerSecondaryAction(
      icon: Icons.visibility_outlined,
      tooltip: LocaleKeys.matchmaker_users_action_view.t(context),
      onTap: () => onView?.call(),
    );
    final interests = MatchmakerSecondaryAction(
      icon: Icons.favorite_border_rounded,
      tooltip: LocaleKeys.matchmaker_users_action_interests.t(context),
      onTap: () => onInterests?.call(),
    );
    return switch (list) {
      // Pending's primary is موافقة, so عرض joins the secondaries here.
      MatchmakerUsersList.pending => [message, view, notes],
      MatchmakerUsersList.approvedUnsubscribed => [message, notes],
      MatchmakerUsersList.approvedSubscribed => [message, notes, interests],
    };
  }

  /// موافقة → confirm sheet (approve / reject-with-reason). On success the
  /// sheet pops `true`; we bubble it up via [onMutated] so the list refreshes.
  Future<void> _openReviewSheet(BuildContext context) async {
    final mutated = await showMatchmakerReviewSheet(
      context,
      userId: row.userId,
      hasNoImage: row.hasProfileImage == false,
      imageRequestStatus: row.imageRequestStatus,
    );
    if (mutated == true) onMutated?.call();
  }

  /// Subscription-expiry label pinned top-end (subscribed rows only).
  String? _expiryLabel(BuildContext context) {
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
