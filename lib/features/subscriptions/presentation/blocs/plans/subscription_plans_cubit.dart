import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';

import '../../../domain/entities/subscription_plan.dart';
import '../../../domain/entities/subscription_pricing.dart';
import '../../../domain/usecases/get_subscription_plans_usecase.dart';
import 'subscription_plans_state.dart';

/// Screen-scoped cubit for the Packages screen. Loads the plans list,
/// computes a default `pricingId` per plan, and lets the UI swap the
/// selection per-plan via [selectPricing]. The cubit doesn't navigate
/// to purchase — it just exposes the selected pricing through
/// [pricingFor] so the screen can route on CTA tap.
class SubscriptionPlansCubit extends Cubit<SubscriptionPlansState> {
  final GetSubscriptionPlansUseCase _getPlans;

  SubscriptionPlansCubit({required GetSubscriptionPlansUseCase getPlans})
      : _getPlans = getPlans,
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
        _logPlanIdentifiersOnce(active);
        final selection = <int, int>{};
        for (final plan in active) {
          final defaultPricing = _defaultPricingFor(plan);
          if (defaultPricing != null) selection[plan.id] = defaultPricing.id;
        }
        emit(SubscriptionPlansLoaded(
          plans: active,
          selectionByPlan: selection,
        ));
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

  // TODO(payments-mapping): one-shot debug log — prints the real backend
  // (planId, nameEn, nameAr, pricingId, durationDays, price) so the RC
  // product map can be keyed off verified values rather than assumptions.
  // Remove once the backend exposes `storeProductId` on each pricing.
  static bool _loggedIdsOnce = false;
  static void _logPlanIdentifiersOnce(List<SubscriptionPlan> plans) {
    if (_loggedIdsOnce) return;
    _loggedIdsOnce = true;
    for (final p in plans) {
      for (final pr in p.pricings) {
        AppLogger.debug(
          '[PLANS_DEBUG] planId=${p.id} nameEn=${p.nameEn} '
          'nameAr=${p.nameAr} pricingId=${pr.id} '
          'durationDays=${pr.durationDays} price=${pr.price}',
          tag: 'PAYMENTS',
        );
      }
    }
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
