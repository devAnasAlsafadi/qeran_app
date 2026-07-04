import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';

import '../../../domain/entities/subscription_plan.dart';
import '../../../domain/entities/subscription_pricing.dart';
import '../../../domain/usecases/get_store_products_usecase.dart';
import '../../../domain/usecases/get_subscription_plans_usecase.dart';
import 'subscription_plans_state.dart';

/// Screen-scoped cubit for the Packages screen. Loads the plans list,
/// computes a default `pricingId` per plan, and lets the UI swap the
/// selection per-plan via [selectPricing]. The cubit doesn't navigate
/// to purchase — it just exposes the selected pricing through
/// [pricingFor] so the screen can route on CTA tap.
///
/// Prices are store-driven: after the backend plans paint, the RevenueCat
/// store catalogue is fetched and merged in a second emit. The store fetch is
/// best-effort — a failure leaves `storeProducts` empty and the paywall
/// degrades to backend prices, never blocking on the store.
class SubscriptionPlansCubit extends Cubit<SubscriptionPlansState> {
  final GetSubscriptionPlansUseCase _getPlans;
  final GetStoreProductsUseCase _getStoreProducts;

  SubscriptionPlansCubit({
    required GetSubscriptionPlansUseCase getPlans,
    required GetStoreProductsUseCase getStoreProducts,
  })  : _getPlans = getPlans,
        _getStoreProducts = getStoreProducts,
        super(const SubscriptionPlansInitial());

  Future<void> load() async {
    emit(const SubscriptionPlansLoading());
    final result = await _getPlans();
    if (isClosed) return;
    result.fold(
      (failure) => emit(SubscriptionPlansFailure(failure.message)),
      (plans) {
        // Filter inactive plans, preserve server sortOrder (server already
        // sorts but we re-sort defensively).
        final active = plans.where((p) => p.isActive).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        final selection = <int, int>{};
        for (final plan in active) {
          final defaultPricing = _defaultPricingFor(plan);
          if (defaultPricing != null) selection[plan.id] = defaultPricing.id;
        }
        // First emit: paint immediately on backend prices; store prices
        // augment in a second emit once the catalogue resolves.
        emit(SubscriptionPlansLoaded(
          plans: active,
          selectionByPlan: selection,
        ));
      },
    );
    await _augmentWithStoreProducts();
  }

  /// Fetches the RC store catalogue and merges it into the current
  /// [SubscriptionPlansLoaded]. Best-effort: a store failure (or a state that
  /// has since moved off Loaded) is a silent no-op so the paywall stays on
  /// backend-price fallback.
  Future<void> _augmentWithStoreProducts() async {
    final current = state;
    if (current is! SubscriptionPlansLoaded) return;
    final result = await _getStoreProducts();
    if (isClosed) return;
    result.fold(
      (failure) => AppLogger.warning(
        'Store products unavailable (${failure.message}) — '
        'paywall stays on backend prices',
        tag: 'PAYMENTS',
      ),
      (products) {
        if (products.isEmpty) return;
        final latest = state;
        if (latest is! SubscriptionPlansLoaded) return;
        emit(latest.copyWith(storeProducts: products));
      },
    );
  }

  /// Swaps the active pricing for a plan; no-op if [pricingId] isn't
  /// one of the plan's pricings. Emits a new state so the UI rebuilds.
  void selectPricing({required int planId, required int pricingId}) {
    final s = state;
    if (s is! SubscriptionPlansLoaded) return;
    final plan = s.plans.firstWhere(
      (p) => p.id == planId,
      orElse: () => s.plans.first,
    );
    final exists = plan.pricings.any((p) => p.id == pricingId && p.isActive);
    if (!exists) return;
    if (s.selectionByPlan[planId] == pricingId) return;
    final next = Map<int, int>.of(s.selectionByPlan)..[planId] = pricingId;
    emit(s.copyWith(selectionByPlan: next));
  }

  /// Returns the currently-selected pricing for [planId] or `null` if
  /// the plan has no active pricings.
  SubscriptionPricing? pricingFor(SubscriptionPlan plan) {
    final s = state;
    if (s is! SubscriptionPlansLoaded) return null;
    final pricingId = s.selectionByPlan[plan.id];
    if (pricingId == null) return null;
    for (final p in plan.pricings) {
      if (p.id == pricingId) return p;
    }
    return null;
  }

  static SubscriptionPricing? _defaultPricingFor(SubscriptionPlan plan) {
    final active = plan.activePricings;
    if (active.isEmpty) return null;
    for (final p in active) {
      if (p.isPopular) return p;
    }
    return active.first;
  }
}
