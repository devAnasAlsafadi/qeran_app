import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../domain/entities/matchmaker_users_list.dart';
import '../blocs/subscription_plans_cubit.dart';
import '../blocs/subscription_plans_state.dart';
import 'matchmaker_plan_filter_rail.dart';
import 'matchmaker_users_list_view.dart';

/// The مشتركون page: provides the [SubscriptionPlansCubit] (loaded once) for
/// both the plan-filter rail and the subscribed list beneath it. The list is
/// `planFiltered`, so it re-fetches server-side when a chip is selected. The
/// rail self-hides until plans load (and stays hidden if they fail), so this
/// degrades cleanly to the plain subscribed list.
class MatchmakerSubscribedWithPlanFilter extends StatelessWidget {
  const MatchmakerSubscribedWithPlanFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SubscriptionPlansCubit>(
      create: (_) => sl<SubscriptionPlansCubit>()..load(),
      child: Column(
        children: [
          const MatchmakerPlanFilterRail(),
          // Hide the per-card plan chip once a specific plan is selected (then
          // every card is that plan — the chip is redundant). `isAll` rebuilds
          // only the list-view, not its cubit (BlocProvider create is stable).
          Expanded(
            child: BlocSelector<SubscriptionPlansCubit, SubscriptionPlansState,
                bool>(
              selector: (state) => state.selectedPlanId == null,
              builder: (context, isAll) => MatchmakerUsersListView(
                list: MatchmakerUsersList.approvedSubscribed,
                planFiltered: true,
                showPlanChip: isAll,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
