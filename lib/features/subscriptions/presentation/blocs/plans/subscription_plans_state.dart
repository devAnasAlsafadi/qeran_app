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
/// progressive emit) and is empty until — or if — the store resolves. The store
/// price is the ONLY price ever displayed: the backend `price` is an
/// administrative figure that does not match what the store charges, so showing
/// it would misstate the amount the user is about to pay.
///
/// [storeResolved] distinguishes the two reasons [storeProductFor] can return
/// null. False means the catalogue request is still in flight and the price is
/// merely late (render a placeholder); true means it finished and this product
/// genuinely has no store entry, which is terminal — the price is unknowable
/// and the purchase would fail anyway.
final class SubscriptionPlansLoaded extends SubscriptionPlansState {
  final List<SubscriptionPlan> plans;
  final Map<int, int> selectionByPlan;
  final Map<String, StoreProduct> storeProducts;
  final bool storeResolved;

  const SubscriptionPlansLoaded({
    required this.plans,
    required this.selectionByPlan,
    this.storeProducts = const {},
    this.storeResolved = false,
  });

  SubscriptionPlansLoaded copyWith({
    List<SubscriptionPlan>? plans,
    Map<int, int>? selectionByPlan,
    Map<String, StoreProduct>? storeProducts,
    bool? storeResolved,
  }) =>
      SubscriptionPlansLoaded(
        plans: plans ?? this.plans,
        selectionByPlan: selectionByPlan ?? this.selectionByPlan,
        storeProducts: storeProducts ?? this.storeProducts,
        storeResolved: storeResolved ?? this.storeResolved,
      );

  /// Purchasable plans only — the free tier is represented by the dedicated
  /// free card, so it's filtered out of the selectable list to avoid a double
  /// render. Keyed on the reliable [SubscriptionPlan.isFree] flag (≡ tier 0);
  /// order preserved.
  List<SubscriptionPlan> get paidPlans =>
      plans.where((p) => !p.isFree).toList(growable: false);

  /// The single free-tier plan (`isFree` ≡ tier 0), or null when the payload
  /// carries no free plan. The free card reads its feature bullets / quotas
  /// from this, so it renders the same backend data as the paid cards.
  SubscriptionPlan? get freePlan {
    for (final p in plans) {
      if (p.isFree) return p;
    }
    return null;
  }

  /// The store product backing [pricing] on the current platform, or null when
  /// the store has no entry for it — read [storeResolved] to tell "not yet"
  /// from "never". Keys off the pricing's canonical/​platform store id via
  /// `productId(isIOS:)`.
  StoreProduct? storeProductFor(
    SubscriptionPricing pricing, {
    required bool isIOS,
  }) {
    final id = pricing.productId(isIOS: isIOS);
    if (id == null) return null;
    return storeProducts[id];
  }

  @override
  List<Object?> get props =>
      [plans, selectionByPlan, storeProducts, storeResolved];
}

final class SubscriptionPlansFailure extends SubscriptionPlansState {
  final String message;
  const SubscriptionPlansFailure(this.message);

  @override
  List<Object?> get props => [message];
}
