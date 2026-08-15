import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_app_bar.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../home/presentation/home_shell_scope.dart';
import '../../../notifications/presentation/blocs/matchmaker_notification_badge_cubit.dart';
import '../../data/matchmaker_notification_router.dart';

/// App bar for every Matchmaker shell screen.
///
/// Composes the design-system [QeranAppBar] and adds the two top-level
/// destinations that aren't bottom-nav tabs:
///   • notifications (bell)  → `RouteNames.matchmakerNotifications`
///   • account / settings    → `RouteNames.matchmakerAccount`
///
/// The bell shows a small gold dot when [hasUnreadNotifications] is true.
///
/// [onBack] is forwarded to [QeranAppBar]. A tab has nothing to pop, so it is
/// normally null and no leading is drawn; a tab reached FROM the notification
/// inbox passes one so the user can get back there.
class MatchmakerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MatchmakerAppBar({
    super.key,
    required this.title,
    this.hasUnreadNotifications = false,
    this.onBack,
  });

  final String title;
  final bool hasUnreadNotifications;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return QeranAppBar(
      title: title,
      onBack: onBack,
      actions: [
        _BellAction(showDot: hasUnreadNotifications),
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
  const _BellAction({required this.showDot});

  /// Caller-forced dot (legacy flag). OR'd with the live unread badge below.
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchmakerNotificationBadgeCubit, int>(
      bloc: sl<MatchmakerNotificationBadgeCubit>(),
      builder: (context, unread) {
        final dot = showDot || unread > 0;
        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                size: 24,
                color: QeranColors.wine,
              ),
              if (dot)
                const PositionedDirectional(
                  top: -1,
                  end: -1,
                  child: _GoldDot(),
                ),
            ],
          ),
          onPressed: () => _openInbox(context),
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

class _GoldDot extends StatelessWidget {
  const _GoldDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: QeranColors.gold,
        shape: BoxShape.circle,
      ),
    );
  }
}
