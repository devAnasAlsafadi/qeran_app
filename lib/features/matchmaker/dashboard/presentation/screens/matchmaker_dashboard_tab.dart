import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../account/presentation/blocs/matchmaker_account_cubit.dart';
import '../../../home/presentation/home_shell_scope.dart';
import '../../../shared/presentation/widgets/matchmaker_app_bar.dart';
import '../blocs/matchmaker_dashboard_cubit.dart';
import '../blocs/matchmaker_dashboard_state.dart';
import '../widgets/matchmaker_dashboard_body.dart';

/// Dashboard tab — six quick-stat counters from `GET /matchmaker/dashboard`.
/// Each card is a tappable shortcut to its related tab.
///
/// The `MatchmakerDashboardCubit` is provided by the shell
/// (`MatchmakerHomeScreen`), not here, so the Users tab's pending badge
/// can read the same stats. This tab only consumes it.
class MatchmakerDashboardTab extends StatelessWidget {
  const MatchmakerDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    // The greeting name is NOT in the session for moderators (the login
    // payload carries no name, so `userName` is never persisted). Source it
    // from the authoritative `/matchmaker/me` via a screen-scoped account
    // cubit; fall back to any session name while it loads / on failure.
    return BlocProvider<MatchmakerAccountCubit>(
      create: (_) => sl<MatchmakerAccountCubit>()..load(),
      child: Scaffold(
        backgroundColor: QeranColors.creamCanvas,
        appBar: MatchmakerAppBar(
          title: LocaleKeys.matchmaker_nav_dashboard.t(context),
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: BlocBuilder<MatchmakerDashboardCubit, MatchmakerDashboardState>(
            builder: (context, state) => switch (state) {
              MatchmakerDashboardLoaded(:final stats) => RefreshIndicator(
                  color: QeranColors.wine,
                  backgroundColor: QeranColors.paper,
                  onRefresh: () =>
                      context.read<MatchmakerDashboardCubit>().refresh(),
                  child: MatchmakerDashboardBody(
                    stats: stats,
                    matchmakerName: _resolveName(context),
                    onOpen: (index, {usersSubTab}) =>
                        MatchmakerHomeShellScope.maybeOf(context)
                            ?.openTab(index, usersSubTab: usersSubTab),
                  ),
                ),
              MatchmakerDashboardError(:final message) => QeranErrorState(
                  title: LocaleKeys.matchmaker_dashboard_error_title.t(context),
                  message: message,
                  retryLabel: LocaleKeys.matchmaker_dashboard_retry.t(context),
                  onRetry: () =>
                      context.read<MatchmakerDashboardCubit>().retry(),
                ),
              _ => const MatchmakerDashboardBodySkeleton(),
            },
          ),
        ),
      ),
    );
  }

  /// Prefer the authoritative `/matchmaker/me` name (watched so the greeting
  /// updates when it lands); fall back to any non-empty session name.
  String? _resolveName(BuildContext context) {
    final meName = context.watch<MatchmakerAccountCubit>().state.me?.name;
    if (meName != null && meName.trim().isNotEmpty) return meName;
    return context.read<UserSessionCubit>().currentUser?.name;
  }
}
