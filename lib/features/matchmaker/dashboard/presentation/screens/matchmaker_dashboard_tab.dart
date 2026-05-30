import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../home/presentation/home_shell_scope.dart';
import '../../../shared/presentation/widgets/matchmaker_app_bar.dart';
import '../blocs/matchmaker_dashboard_cubit.dart';
import '../blocs/matchmaker_dashboard_state.dart';
import '../widgets/matchmaker_stats_grid.dart';

/// Dashboard tab — six quick-stat counters from `GET /matchmaker/dashboard`.
/// Each card is a tappable shortcut to its related tab.
class MatchmakerDashboardTab extends StatelessWidget {
  const MatchmakerDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MatchmakerDashboardCubit>(
      create: (_) => sl<MatchmakerDashboardCubit>()..load(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: MatchmakerAppBar(
        title: LocaleKeys.matchmaker_nav_dashboard.t(context),
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<MatchmakerDashboardCubit, MatchmakerDashboardState>(
          builder: (context, state) => switch (state) {
            MatchmakerDashboardLoaded(:final stats) => RefreshIndicator(
                color: QeranColors.wine,
                backgroundColor: QeranColors.paper,
                onRefresh: () =>
                    context.read<MatchmakerDashboardCubit>().refresh(),
                child: MatchmakerStatsGrid(
                  stats: stats,
                  onOpenTab: (tab) =>
                      MatchmakerHomeShellScope.maybeOf(context)?.openTab(tab),
                ),
              ),
            MatchmakerDashboardError(:final message) => QeranErrorState(
                title: LocaleKeys.matchmaker_dashboard_error_title.t(context),
                message: message,
                retryLabel: LocaleKeys.matchmaker_dashboard_retry.t(context),
                onRetry: () =>
                    context.read<MatchmakerDashboardCubit>().retry(),
              ),
            _ => const MatchmakerStatsGridSkeleton(),
          },
        ),
      ),
    );
  }
}
