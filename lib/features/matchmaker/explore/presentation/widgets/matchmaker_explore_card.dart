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
import '../../domain/entities/matchmaker_explore_user.dart';

/// One explore result — a 54px rounded-square photo/monogram + name, a single
/// top-end OWNERSHIP chip (gold "مستخدمي" when assigned to me, else the owning
/// matchmaker's name in a soft wine chip), ≤3 fact chips + age, and an
/// ownership-conditional action bar (gold **عرض** primary + two icon-only
/// secondaries: mine → ملاحظات + مشاركة; other → مراسلة الخطّابة + مشاركة).
class MatchmakerExploreCard extends StatelessWidget {
  const MatchmakerExploreCard({
    super.key,
    required this.user,
    required this.onView,
    required this.onShare,
    this.onNotes,
    this.onMessageMatchmaker,
    this.matchmakerLoading = false,
  });

  final MatchmakerExploreUser user;

  /// Opens the full profile (the explore primary action).
  final VoidCallback onView;

  /// Opens the recipient picker to share this profile with my users.
  final VoidCallback onShare;

  /// Opens the private notes sheet — null (hidden) unless the user is assigned
  /// to me (the note endpoint is assigned-only).
  final VoidCallback? onNotes;

  /// Opens the chat with this user's matchmaker — null (hidden) unless the user
  /// has a different matchmaker.
  final VoidCallback? onMessageMatchmaker;

  /// True while that matchmaker chat is resolving on tap.
  final bool matchmakerLoading;

  static const double _avatarSize = 54;

  @override
  Widget build(BuildContext context) {
    final hasFacts = user.answers.isNotEmpty || user.age != null;
    final ownership = _ownershipChip(context);

    return QeranCard(
      margin: const EdgeInsets.only(bottom: QeranSpacing.s12),
      padding: const EdgeInsets.all(QeranSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MatchmakerUserAvatar(
                url: user.profileImageUrl,
                size: _avatarSize,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(16),
                monogramName: user.fullName,
              ),
              QeranSpacing.hs12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.fullName,
                      style: QeranTypography.subtitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasFacts) ...[
                      QeranSpacing.vs8,
                      MatchmakerFactChips(
                        facts: [for (final a in user.answers) a.answer],
                        age: user.age,
                      ),
                    ],
                  ],
                ),
              ),
              // The single ownership signal, pinned top-END — mirrors in RTL.
              if (ownership != null) ...[QeranSpacing.hs8, ownership],
            ],
          ),
          QeranSpacing.vs12,
          MatchmakerCardActionBar(
            primary: MatchmakerPrimaryAction(
              label: LocaleKeys.matchmaker_users_action_view.t(context),
              icon: Icons.visibility_outlined,
              onTap: onView,
            ),
            secondaries: _secondaries(context),
          ),
        ],
      ),
    );
  }

  /// Exactly one ownership chip, or null when the user is unassigned: a gold
  /// "مستخدمي" badge when mine, else the owning matchmaker's name (name only —
  /// no owner avatar exists) in a soft wine chip.
  Widget? _ownershipChip(BuildContext context) {
    if (user.isMyAssigned) {
      return QeranChip(
        label: LocaleKeys.matchmaker_explore_assigned_to_me.t(context),
        variant: QeranChipVariant.interest,
        compact: true,
        icon: Icons.verified_rounded,
      );
    }
    final owner = user.assignedMatchmakerName?.trim() ?? '';
    if (owner.isEmpty) return null;
    return QeranChip(
      label: owner,
      variant: QeranChipVariant.status,
      statusColor: QeranColors.wine,
      compact: true,
      icon: Icons.shield_outlined,
      maxWidth: 120,
    );
  }

  /// Ownership-conditional secondaries: mine → Notes + Share; other party →
  /// Matchmaker chat + Share. The list gates which callbacks are non-null.
  List<MatchmakerSecondaryAction> _secondaries(BuildContext context) {
    return [
      if (onNotes != null)
        MatchmakerSecondaryAction(
          icon: Icons.sticky_note_2_outlined,
          tooltip: LocaleKeys.matchmaker_users_action_notes.t(context),
          onTap: onNotes!,
        ),
      if (onMessageMatchmaker != null)
        MatchmakerSecondaryAction(
          icon: Icons.forum_outlined,
          tooltip:
              LocaleKeys.matchmaker_cases_action_message_matchmaker.t(context),
          onTap: onMessageMatchmaker!,
          loading: matchmakerLoading,
        ),
      MatchmakerSecondaryAction(
        icon: Icons.ios_share_rounded,
        tooltip: LocaleKeys.matchmaker_explore_action_share.t(context),
        onTap: onShare,
      ),
    ];
  }
}
