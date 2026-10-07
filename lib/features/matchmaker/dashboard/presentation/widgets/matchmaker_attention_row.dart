import 'package:flutter/material.dart';

import '../../../../../core/design_system/motion/soft_scale_in.dart';
import '../../../../../core/design_system/tokens/qeran_motion.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../home/presentation/home_shell_scope.dart';
import '../../../users/domain/entities/matchmaker_users_list.dart';
import '../../domain/entities/matchmaker_dashboard_stats.dart';
import 'matchmaker_attention_card.dart';
import 'matchmaker_dashboard_tabs.dart';

/// «تحتاج انتباهك»'s two heroes: pending reviews and unread messages.
class MatchmakerAttentionRow extends StatelessWidget {
  const MatchmakerAttentionRow({
    super.key,
    required this.stats,
    required this.onOpen,
  });

  final MatchmakerDashboardStats stats;
  final MatchmakerOpenTab onOpen;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SoftScaleIn(
            duration: QeranMotion.standard,
            child: MatchmakerAttentionCard(
              icon: Icons.pending_actions_outlined,
              count: stats.pendingUsersCount,
              label: LocaleKeys.matchmaker_dashboard_pending.t(context),
              actionLabel:
                  LocaleKeys.matchmaker_dashboard_hero_action.t(context),
              zeroLabel:
                  LocaleKeys.matchmaker_dashboard_pending_zero.t(context),
              onTap: () => onOpen(MatchmakerDashboardTabs.users,
                  usersSubTab: MatchmakerUsersList.pending),
            ),
          ),
        ),
        QeranSpacing.hs12,
        Expanded(
          child: SoftScaleIn(
            duration: QeranMotion.standard,
            delay: QeranMotion.staggerStep,
            child: MatchmakerAttentionCard(
              icon: Icons.mark_chat_unread_outlined,
              count: stats.unreadMessagesCount,
              label: LocaleKeys.matchmaker_dashboard_unread_messages.t(context),
              actionLabel:
                  LocaleKeys.matchmaker_dashboard_hero_action.t(context),
              zeroLabel:
                  LocaleKeys.matchmaker_dashboard_unread_zero.t(context),
              onTap: () => onOpen(MatchmakerDashboardTabs.conversations),
            ),
          ),
        ),
      ],
    );
  }
}
