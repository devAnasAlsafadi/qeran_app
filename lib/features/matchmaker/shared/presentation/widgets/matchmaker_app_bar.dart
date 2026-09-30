import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_app_bar.dart';
import '../../../../../core/design_system/widgets/qeran_bell_button.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../badges/domain/entities/badge_counts.dart';
import '../../../../badges/presentation/blocs/badges_cubit.dart';
import '../../../home/presentation/home_shell_scope.dart';
import '../../data/matchmaker_notification_router.dart';

/// App bar for every Matchmaker shell screen.
///
/// Composes the design-system [QeranAppBar] and adds the two top-level
/// destinations that aren't bottom-nav tabs:
///   • notifications (bell)  → `RouteNames.matchmakerNotifications`
///   • account / settings    → `RouteNames.matchmakerAccount`
///
/// The bell carries the server's unread count when there is one.
///
/// [onBack] is forwarded to [QeranAppBar]. A tab has nothing to pop, so it is
/// normally null and no leading is drawn; a tab reached FROM the notification
/// inbox passes one so the user can get back there.
class MatchmakerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MatchmakerAppBar({
    super.key,
    required this.title,
    this.onBack,
  });

  final String title;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return QeranAppBar(
      title: title,
      onBack: onBack,
      actions: [
        const _BellAction(),
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 24),
          color: QeranColors.wine,
          tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
          onPressed: () => Navigator.of(context)
              .pushNamed(RouteNames.matchmakerAccount),
        ),
      ],
    );
  }
}

class _BellAction extends StatelessWidget {
  const _BellAction();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BadgesCubit, BadgeCounts>(
      bloc: sl<BadgesCubit>(),
      builder: (context, counts) {
        return QeranBellButton(
          count: counts.notifications,
          onTap: () => _openInbox(context),
          // The size of the gear beside it.
          size: 24,
        );
      },
    );
  }

  /// Opens the inbox and applies whatever the user taps there.
  ///
  /// A Cases row can't navigate on its own — the tab lives in the shell BELOW
  /// this route — so the inbox pops the intent and it is applied here, from a
  /// caller that IS inside the shell. Mirrors the user app's
  /// `openNotifications`.
  Future<void> _openInbox(BuildContext context) async {
    // Captured BEFORE the await — no BuildContext use across the gap.
    final shell = MatchmakerHomeShellScope.maybeOf(context);
    final result = await Navigator.of(
      context,
    ).pushNamed(RouteNames.matchmakerNotifications);
    if (shell == null || result is! MatchmakerDeepLink) return;
    shell.openFromNotification(result);
  }
}
