import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';

import '../../domain/usecases/fetch_subscription_plans_usecase.dart';
import 'subscription_plans_state.dart';

/// Owns the مشتركون plan-filter rail: loads the dynamic plan list once and
/// holds the selected plan ([SubscriptionPlansState.selectedPlanId]; `null` =
/// "All"). The selection drives the subscribed list's server-side `planId`
/// filter (Step C wires that).
///
/// Mounted once with the subscribed list, so [load] runs a single time. The
/// rail is additive — a load failure leaves the list unfiltered ("All" only).
class SubscriptionPlansCubit extends Cubit<SubscriptionPlansState> with SafeEmit<SubscriptionPlansState> {
  final FetchSubscriptionPlansUseCase _fetchPlans;

  SubscriptionPlansCubit({required FetchSubscriptionPlansUseCase fetchPlans})
      : _fetchPlans = fetchPlans,
        super(const SubscriptionPlansState());

  /// Fetches the plan list once. Idempotent: a second call while loading or
  /// after a successful load is a no-op (the rail doesn't refetch on every
  /// sub-tab switch). On failure it surfaces [SubscriptionPlansStatus.error]
  /// without clearing any prior plans.
  Future<void> load() async {
    if (state.isLoading || state.status == SubscriptionPlansStatus.loaded) {
      return;
    }
    emit(state.copyWith(status: SubscriptionPlansStatus.loading));
    final result = await _fetchPlans();
    result.fold(
      (_) {
        if (!isClosed) {
          emit(state.copyWith(status: SubscriptionPlansStatus.error));
        }
      },
      (plans) {
        if (!isClosed) {
          emit(state.copyWith(
            status: SubscriptionPlansStatus.loaded,
            plans: plans,
          ));
        }
      },
    );
  }

  /// Retry after an error.
  Future<void> retry() async {
    emit(state.copyWith(status: SubscriptionPlansStatus.initial));
    await load();
  }

  /// Selects a plan (or "All" when [planId] is null). No-op when unchanged so
  /// the subscribed list doesn't refetch on a redundant tap.
  void select(int? planId) {
    if (planId == state.selectedPlanId) return;
    if (planId == null) {
      emit(state.copyWith(clearSelection: true));
    } else {
      emit(state.copyWith(selectedPlanId: planId));
    }
  }
}
