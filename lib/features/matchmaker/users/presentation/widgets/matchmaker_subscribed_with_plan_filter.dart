import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../domain/entities/matchmaker_users_list.dart';
import '../blocs/subscription_plans_cubit.dart';
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
        children: const [
          MatchmakerPlanFilterRail(),
          Expanded(
            child: MatchmakerUsersListView(
              list: MatchmakerUsersList.approvedSubscribed,
              planFiltered: true,
            ),
          ),
        ],
      ),
    );
  }
}
