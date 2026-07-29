import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/services/revenuecat_service.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../domain/entities/subscription_pricing.dart';
import '../../../domain/entities/validate_code_response.dart';
import '../../../domain/usecases/purchase_package_usecase.dart';
import '../../../domain/usecases/restore_purchases_usecase.dart';
import '../../../domain/usecases/validate_code_usecase.dart';
import '../current/current_subscription_cubit.dart';
import 'package_purchase_messages.dart';
import 'package_purchase_state.dart';

/// Screen-scoped orchestrator for the paywall purchase flow: discount-code
/// validation, the RevenueCat purchase (Android only — iOS is locked per Q-B),
/// restore, and the post-purchase reconcile (Q-C). It does NOT handle the free
/// tier — that routes through `SubscribeUseCase` at the CTA (Commit 5).
class PackagePurchaseCubit extends Cubit<PackagePurchaseState> with SafeEmit<PackagePurchaseState> {
  final ValidateCodeUseCase _validateCode;
  final PurchasePackageUseCase _purchasePackage;
  final RestorePurchasesUseCase _restorePurchases;
  final CurrentSubscriptionCubit _currentSubscription;
  final RevenueCatService _revenueCat;

  /// Delays between successive `/current` re-fetches while waiting out the
  /// post-purchase webhook lag (the 204 window). Injectable so tests can run
  /// the backoff with zero delay. Defaults to [_kReconcileBackoff].
  final List<Duration> _reconcileBackoff;

  /// ~11s across 4 retries (plus the immediate fetch = 5 attempts). Sized for
  /// RevenueCat webhook → `/current` activation lag without an unbounded loop.
  static const List<Duration> _kReconcileBackoff = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 3),
    Duration(seconds: 5),
  ];

  PackagePurchaseCubit({
    required ValidateCodeUseCase validateCode,
    required PurchasePackageUseCase purchasePackage,
    required RestorePurchasesUseCase restorePurchases,
    required CurrentSubscriptionCubit currentSubscription,
    required RevenueCatService revenueCat,
    List<Duration> reconcileBackoff = _kReconcileBackoff,
  })  : _validateCode = validateCode,
        _purchasePackage = purchasePackage,
        _restorePurchases = restorePurchases,
        _currentSubscription = currentSubscription,
        _revenueCat = revenueCat,
        _reconcileBackoff = reconcileBackoff,
        super(const PackagePurchaseIdle());

  CustomerInfoUpdateListener? _entitlementListener;

  /// Prevents overlapping purchase/restore reconciles from stacking backoff
  /// loops. Reset in the loop's `finally`.
  bool _reconcileInFlight = false;

  /// Validates [code] against [productId] for the current platform. Emits
  /// [PackagePurchaseValidatingCode] then success/failure. A server `valid:false`
  /// surfaces as [PackagePurchaseCodeValidationFailure] with the server message.
  Future<void> validateDiscountCode({
    required String code,
    required String productId,
  }) async {
    emit(const PackagePurchaseValidatingCode());
    final platform = Platform.isIOS ? 'ios' : 'android';
    final result = await _validateCode(
      code: code,
      productId: productId,
      platform: platform,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        PackagePurchaseCodeValidationFailure(message: failure.message),
      ),
      (response) => emit(
        response.valid
            ? PackagePurchaseCodeValidationSuccess(response: response)
            : PackagePurchaseCodeValidationFailure(
                message: response.message ?? LocaleKeys.errors_generic,
              ),
      ),
    );
  }

  /// Buys [pricing] (Android only). [validatedCode] carries an applied offer;
  /// [oldProductId] (a different owned product) drives an upgrade.
  Future<void> purchase({
    required SubscriptionPricing pricing,
    ValidateCodeResponse? validatedCode,
    String? oldProductId,
  }) async {
    if (Platform.isIOS) {
      emit(const PackagePurchaseFailure(
        failure: PlatformNotSupportedFailure(),
        userMessage: LocaleKeys.subscriptions_purchase_ios_coming_soon,
      ));
      return;
    }

    final productId = pricing.productId(isIOS: Platform.isIOS) ??
        pricing.googleProductId ??
        pricing.storeProductId;
    if (productId == null || productId.isEmpty) {
      emit(const PackagePurchaseFailure(
        failure: NotFoundFailure(),
        userMessage: LocaleKeys.subscriptions_purchase_package_not_found,
      ));
      return;
    }

    // Same product already owned → nothing to buy (upgrades to a *different*
    // product are allowed and proceed).
    if (oldProductId != null && oldProductId == productId) {
      emit(const PackagePurchaseFailure(
        failure: AlreadyOwnedFailure(),
        userMessage: LocaleKeys.subscriptions_purchase_already_subscribed,
      ));
      return;
    }

    emit(const PackagePurchaseInProgress());
    final result = await _purchasePackage(
      productId: productId,
      offerId: validatedCode?.offerId,
      signature: validatedCode?.signature,
      keyId: validatedCode?.keyId,
      nonce: validatedCode?.nonce,
      timestampMs: validatedCode?.timestampMs,
      oldProductId: oldProductId,
    );
    if (isClosed) return;
    result.fold(_emitFailure, _onPurchased);
  }

  /// Restores prior purchases (allowed on every platform). Reuses the
  /// post-purchase reconcile.
  Future<void> restorePurchases() async {
    emit(const PackagePurchaseInProgress());
    final result = await _restorePurchases();
    if (isClosed) return;
    result.fold(_emitFailure, _onPurchased);
  }

  /// Back to the resting state — e.g. when the user clears a code or dismisses
  /// an error.
  void reset() => emit(const PackagePurchaseIdle());

  void _onPurchased(CustomerInfo customerInfo) {
    _reconcileAfterPurchase();
    emit(PackagePurchaseSuccess(customerInfo: customerInfo));
  }

  // Post-purchase reconcile (Q-C): success is emitted from RC's local
  // entitlement above; /current (SOT for plan/counters) reconciles here with a
  // bounded backoff (webhook lag can leave /current at 204 briefly), and a
  // one-time RC listener catches webhook lag independently.
  void _reconcileAfterPurchase() {
    unawaited(_reconcileCurrentWithBackoff());
    _armEntitlementListener();
  }

  /// Re-fetches `/current` immediately, then retries on [_reconcileBackoff]
  /// delays until an active subscription lands — closing the post-purchase 204
  /// window so the user never briefly sees "no subscription" right after
  /// paying. Exits as soon as the sub is active; gives up gracefully after the
  /// bound (the armed RC listener remains as an independent backstop). Guarded
  /// so overlapping purchase/restore reconciles don't stack loops. Touches only
  /// the app-scoped [CurrentSubscriptionCubit], so it's safe if this cubit
  /// closes mid-flight.
  Future<void> _reconcileCurrentWithBackoff() async {
    if (_reconcileInFlight) return;
    _reconcileInFlight = true;
    try {
      _currentSubscription.invalidateCache();
      await _currentSubscription.refresh(force: true);
      if (_currentSubscription.hasActiveSubscription) return;
      for (final delay in _reconcileBackoff) {
        await Future<void>.delayed(delay);
        await _currentSubscription.refresh(force: true);
        if (_currentSubscription.hasActiveSubscription) return;
      }
      // Bound exhausted — leave the last /current state; the RC listener will
      // pull again if the webhook lands later.
    } finally {
      _reconcileInFlight = false;
    }
  }

  /// Single-shot `/current` re-fetch used by the RC entitlement listener (which
  /// fires exactly when the webhook grants premium, so `/current` is ready).
  void _pullCurrentSubscription() {
    _currentSubscription.invalidateCache();
    unawaited(_currentSubscription.refresh(force: true));
  }

  /// Arms a one-time RC entitlement listener: on the next `CustomerInfo`
  /// change (e.g. the webhook granting premium after success was emitted), pull
  /// a fresh `/current`, then disarm. Only touches the app-scoped
  /// [CurrentSubscriptionCubit], so it's safe even if this cubit has closed.
  void _armEntitlementListener() {
    if (_entitlementListener != null) return;
    void listener(CustomerInfo _) {
      _pullCurrentSubscription();
      _disarmEntitlementListener();
    }

    _entitlementListener = listener;
    _revenueCat.addCustomerInfoUpdateListener(listener);
  }

  void _disarmEntitlementListener() {
    final listener = _entitlementListener;
    if (listener == null) return;
    _revenueCat.removeCustomerInfoUpdateListener(listener);
    _entitlementListener = null;
  }

  void _emitFailure(Failure failure) {
    if (failure is UserCancelledFailure) {
      emit(const PackagePurchaseCancelled());
      return;
    }
    if (failure is GenericPurchaseFailure) {
      AppLogger.error(
        'Purchase failed: ${failure.errorCode} — '
        '${failure.underlyingMessage ?? ''}',
        tag: 'PAYMENTS',
      );
    }
    emit(PackagePurchaseFailure(
      failure: failure,
      userMessage: purchaseFailureMessage(failure),
    ));
  }

  @override
  Future<void> close() {
    _disarmEntitlementListener();
    return super.close();
  }
}
