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
        Expanded(child: _pending(context)),
        QeranSpacing.hs12,
        Expanded(child: _unread(context)),
      ],
    );
  }

  Widget _pending(BuildContext context) => _hero(
    context,
    icon: Icons.pending_actions_outlined,
    count: stats.pendingUsersCount,
    labelKey: LocaleKeys.matchmaker_dashboard_pending,
    zeroKey: LocaleKeys.matchmaker_dashboard_pending_zero,
    onTap: () => onOpen(
      MatchmakerDashboardTabs.users,
      usersSubTab: MatchmakerUsersList.pending,
    ),
  );

  Widget _unread(BuildContext context) => _hero(
    context,
    icon: Icons.mark_chat_unread_outlined,
    count: stats.unreadMessagesCount,
    labelKey: LocaleKeys.matchmaker_dashboard_unread_messages,
    zeroKey: LocaleKeys.matchmaker_dashboard_unread_zero,
    onTap: () => onOpen(MatchmakerDashboardTabs.conversations),
    delay: QeranMotion.staggerStep,
  );

  /// One hero card, scaled in after [delay].
  Widget _hero(
    BuildContext context, {
    required IconData icon,
    required int count,
    required String labelKey,
    required String zeroKey,
    required VoidCallback onTap,
    Duration delay = Duration.zero,
  }) {
    return SoftScaleIn(
      duration: QeranMotion.standard,
      delay: delay,
      child: MatchmakerAttentionCard(
        icon: icon,
        count: count,
        label: labelKey.t(context),
        actionLabel: LocaleKeys.matchmaker_dashboard_hero_action.t(context),
        zeroLabel: zeroKey.t(context),
        onTap: onTap,
      ),
    );
  }
}
