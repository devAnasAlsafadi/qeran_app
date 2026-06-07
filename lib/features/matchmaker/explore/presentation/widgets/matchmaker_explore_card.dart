import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/design_system/widgets/qeran_chip.dart';
import '../../../shared/presentation/widgets/matchmaker_user_avatar.dart';
import '../../../users/presentation/widgets/matchmaker_card_answers_block.dart';
import '../../domain/entities/matchmaker_explore_user.dart';

/// One explore result — the M3 card pattern (unblurred avatar + name + flagged
/// answers/age), tappable to open the full profile. When present, the assigned
/// matchmaker's name shows as a small display-only meta chip. No action row
/// (explore is browse-only).
class MatchmakerExploreCard extends StatelessWidget {
  const MatchmakerExploreCard({super.key, required this.user, this.onTap});

  final MatchmakerExploreUser user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final assigned = user.assignedMatchmakerName;
    return QeranCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: QeranSpacing.s12),
      padding: const EdgeInsets.all(QeranSpacing.s12),
      child: Row(
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
                if (assigned != null && assigned.isNotEmpty) ...[
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
    );
  }
}
