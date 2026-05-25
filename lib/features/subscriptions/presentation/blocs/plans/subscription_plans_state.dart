import 'package:equatable/equatable.dart';

import '../../../domain/entities/subscription_plan.dart';

sealed class SubscriptionPlansState extends Equatable {
  const SubscriptionPlansState();

  @override
  List<Object?> get props => const [];
}

final class SubscriptionPlansInitial extends SubscriptionPlansState {
  const SubscriptionPlansInitial();
}

final class SubscriptionPlansLoading extends SubscriptionPlansState {
  const SubscriptionPlansLoading();
}

/// Plans loaded successfully. [selectionByPlan] maps each `plan.id` to
/// the currently-selected `pricing.id`. Defaults to the plan's popular
/// pricing (or its first active pricing if none is flagged).
final class SubscriptionPlansLoaded extends SubscriptionPlansState {
  final List<SubscriptionPlan> plans;
  final Map<int, int> selectionByPlan;

  const SubscriptionPlansLoaded({
    required this.plans,
    required this.selectionByPlan,
  });

  SubscriptionPlansLoaded copyWith({
    List<SubscriptionPlan>? plans,
    Map<int, int>? selectionByPlan,
  }) =>
      SubscriptionPlansLoaded(
        plans: plans ?? this.plans,
        selectionByPlan: selectionByPlan ?? this.selectionByPlan,
      );

  @override
  List<Object?> get props => [plans, selectionByPlan];
}

final class SubscriptionPlansFailure extends SubscriptionPlansState {
  final String message;
  const SubscriptionPlansFailure(this.message);

  @override
  List<Object?> get props => [message];
}
