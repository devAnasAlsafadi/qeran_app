import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/design_system/widgets/qeran_chip.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_user_avatar.dart';
import '../../../users/presentation/widgets/matchmaker_card_answers_block.dart';
import '../../domain/entities/matchmaker_explore_user.dart';
import 'matchmaker_explore_action_row.dart';

/// One explore result — the M3 card pattern (unblurred avatar + name + flagged
/// answers/age) with an action row beneath (View + assigned-only Notes; the
/// matchmaker-chat action lands in a later sub-step). When present, the
/// assignment signal shows as a chip: a gold "assigned to me" badge when mine,
/// else the other matchmaker's name as a muted meta chip.
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

  /// Opens the full profile (the explore primary action — replaces the former
  /// whole-card tap).
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

  @override
  Widget build(BuildContext context) {
    final assigned = user.assignedMatchmakerName;
    return QeranCard(
      margin: const EdgeInsets.only(bottom: QeranSpacing.s12),
      padding: const EdgeInsets.all(QeranSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              MatchmakerUserAvatar(url: user.profileImageUrl, size: 56),
              QeranSpacing.hs12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.fullName,
                      style: QeranTypography.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.answers.isNotEmpty || user.age != null) ...[
                      QeranSpacing.vs4,
                      MatchmakerCardAnswersBlock(
                        answers: user.answers,
                        age: user.age,
                      ),
                    ],
                    // Assignment signal — mutually exclusive: a gold "assigned
                    // to me" badge when mine, else the other matchmaker's name
                    // as a muted meta chip (never both; no green per identity).
                    if (user.isMyAssigned) ...[
                      QeranSpacing.vs8,
                      QeranChip(
                        label: LocaleKeys.matchmaker_explore_assigned_to_me
                            .t(context),
                        variant: QeranChipVariant.interest,
                        compact: true,
                        icon: Icons.verified_user_outlined,
                      ),
                    ] else if (assigned != null && assigned.isNotEmpty) ...[
                      QeranSpacing.vs8,
                      QeranChip(
                        label: assigned,
                        variant: QeranChipVariant.meta,
                        compact: true,
                        icon: Icons.person_outline_rounded,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          QeranSpacing.vs12,
          Container(height: 1, color: QeranColors.divider),
          QeranSpacing.vs12,
          MatchmakerExploreActionRow(
            onView: onView,
            onShare: onShare,
            onNotes: onNotes,
            onMessageMatchmaker: onMessageMatchmaker,
            matchmakerLoading: matchmakerLoading,
          ),
        ],
      ),
    );
  }
}
