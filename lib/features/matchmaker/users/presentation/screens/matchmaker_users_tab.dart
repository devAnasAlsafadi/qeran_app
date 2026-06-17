import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../dashboard/presentation/blocs/matchmaker_dashboard_cubit.dart';
import '../../../dashboard/presentation/blocs/matchmaker_dashboard_state.dart';
import '../../../shared/presentation/widgets/matchmaker_app_bar.dart';
import '../../domain/entities/matchmaker_users_list.dart';
import '../widgets/matchmaker_users_segmented_tabs.dart';
import '../widgets/matchmaker_users_tab_pager.dart';

/// Users management tab — three paginated sub-tabs. Controlled: the
/// active sub-tab lives in the shell so both the segmented control and
/// the dashboard card shortcuts drive it. The three lists sit in a
/// controlled, non-swipeable [MatchmakerUsersTabPager] (keep-alive pages),
/// which slides directionally between them while preserving each list's
/// pagination + scroll across switches.
class MatchmakerUsersTab extends StatelessWidget {
  const MatchmakerUsersTab({
    super.key,
    required this.subTab,
    required this.onSubTabChanged,
  });

  final MatchmakerUsersList subTab;
  final ValueChanged<MatchmakerUsersList> onSubTabChanged;

  @override
  Widget build(BuildContext context) {
    // Pending badge from the shell-provided dashboard cubit (the count is
    // owned by the dashboard, per spec). 0 until the stats load.
    final dashboardState = context.watch<MatchmakerDashboardCubit>().state;
    final pendingBadge = dashboardState is MatchmakerDashboardLoaded
        ? dashboardState.stats.pendingUsersCount
        : 0;

    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: MatchmakerAppBar(
        title: LocaleKeys.matchmaker_nav_users.t(context),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            MatchmakerUsersSegmentedTabs(
              active: subTab,
              onChanged: onSubTabChanged,
              pendingBadge: pendingBadge,
            ),
            Expanded(
              child: MatchmakerUsersTabPager(
                activeIndex: subTab.index,
                onPageChanged: onSubTabChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
