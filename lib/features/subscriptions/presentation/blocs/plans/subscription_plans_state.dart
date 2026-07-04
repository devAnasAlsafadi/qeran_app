import 'package:equatable/equatable.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../domain/entities/subscription_plan.dart';
import '../../../domain/entities/subscription_pricing.dart';

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
///
/// [storeProducts] is the RevenueCat store catalogue keyed by
/// `storeProduct.identifier`. It arrives *after* the plans (a second,
/// progressive emit) and is empty until — or if — the store resolves. The
/// paywall reads the store price as source of truth and falls back to the
/// backend price whenever [storeProductFor] returns null.
final class SubscriptionPlansLoaded extends SubscriptionPlansState {
  final List<SubscriptionPlan> plans;
  final Map<int, int> selectionByPlan;
  final Map<String, StoreProduct> storeProducts;

  const SubscriptionPlansLoaded({
    required this.plans,
    required this.selectionByPlan,
    this.storeProducts = const {},
  });

  SubscriptionPlansLoaded copyWith({
    List<SubscriptionPlan>? plans,
    Map<int, int>? selectionByPlan,
    Map<String, StoreProduct>? storeProducts,
  }) =>
      SubscriptionPlansLoaded(
        plans: plans ?? this.plans,
        selectionByPlan: selectionByPlan ?? this.selectionByPlan,
        storeProducts: storeProducts ?? this.storeProducts,
      );

  /// The store product backing [pricing] on the current platform, or null when
  /// the store hasn't resolved it (⇒ backend-price fallback). Keys off the
  /// pricing's canonical/​platform store id via `productId(isIOS:)`.
  StoreProduct? storeProductFor(
    SubscriptionPricing pricing, {
    required bool isIOS,
  }) {
    final id = pricing.productId(isIOS: isIOS);
    if (id == null) return null;
    return storeProducts[id];
  }

  @override
  List<Object?> get props => [plans, selectionByPlan, storeProducts];
}

final class SubscriptionPlansFailure extends SubscriptionPlansState {
  final String message;
  const SubscriptionPlansFailure(this.message);

  @override
  List<Object?> get props => [message];
}
