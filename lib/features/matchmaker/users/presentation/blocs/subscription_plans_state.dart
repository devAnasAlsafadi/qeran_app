import 'package:equatable/equatable.dart';

import '../../domain/entities/subscription_plan.dart';

enum SubscriptionPlansStatus { initial, loading, loaded, error }

/// State for the مشتركون plan-filter rail: the dynamic plan list plus the
/// currently-selected plan ([selectedPlanId]; `null` = the "All" chip).
///
/// The rail is a soft enhancement — if the plans fail to load, the subscribed
/// list still works unfiltered, so the screen degrades to "All only".
class SubscriptionPlansState extends Equatable {
  final SubscriptionPlansStatus status;
  final List<SubscriptionPlan> plans;

  /// `null` = "All" (no server-side `planId` filter). Otherwise the stable
  /// plan key passed to the subscribed list's fetch.
  final int? selectedPlanId;

  const SubscriptionPlansState({
    this.status = SubscriptionPlansStatus.initial,
    this.plans = const [],
    this.selectedPlanId,
  });

  bool get isLoading => status == SubscriptionPlansStatus.loading;

  /// Whether the rail has anything to show (≥1 plan). The "All" chip alone
  /// isn't worth a rail, so the UI hides it when there are no plans.
  bool get hasPlans => plans.isNotEmpty;

  SubscriptionPlansState copyWith({
    SubscriptionPlansStatus? status,
    List<SubscriptionPlan>? plans,
    int? selectedPlanId,
    bool clearSelection = false,
  }) {
    return SubscriptionPlansState(
      status: status ?? this.status,
      plans: plans ?? this.plans,
      selectedPlanId:
          clearSelection ? null : (selectedPlanId ?? this.selectedPlanId),
    );
  }

  @override
  List<Object?> get props => [status, plans, selectedPlanId];
}
