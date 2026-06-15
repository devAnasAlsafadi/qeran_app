import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/matchmaker_users_list_cubit.dart';
import '../blocs/subscription_plans_cubit.dart';
import '../blocs/subscription_plans_state.dart';

/// Bridges the ancestor [SubscriptionPlansCubit] selection into the subscribed
/// list's [MatchmakerUsersListCubit] — on a chip change, re-fetch from page 1
/// with the new `planId` (server-side filter). Only mounted for the مشتركون
/// list; sits between the list's provider and its body.
class MatchmakerPlanFilterListener extends StatelessWidget {
  const MatchmakerPlanFilterListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SubscriptionPlansCubit, SubscriptionPlansState>(
      listenWhen: (prev, curr) => prev.selectedPlanId != curr.selectedPlanId,
      listener: (context, state) => context
          .read<MatchmakerUsersListCubit>()
          .applyPlanFilter(state.selectedPlanId),
      child: child,
    );
  }
}
