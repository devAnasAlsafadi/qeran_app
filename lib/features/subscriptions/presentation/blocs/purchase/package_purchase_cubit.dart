import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/config/revenuecat_config.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../domain/entities/subscription_pricing.dart';
import '../../../domain/entities/validate_code_response.dart';
import '../../../domain/usecases/purchase_package_usecase.dart';
import '../../../domain/usecases/restore_purchases_usecase.dart';
import '../../../domain/usecases/validate_code_usecase.dart';
import '../current/current_subscription_cubit.dart';
import 'discount_code_keys.dart';
import 'package_purchase_messages.dart';
import 'package_purchase_state.dart';

/// Screen-scoped orchestrator for the paywall purchase flow: discount-code
/// validation, the RevenueCat purchase and restore. What follows a confirmed
/// purchase — waiting for the server — is [CurrentSubscriptionCubit]'s (C5).
/// It does NOT handle the free tier — that routes through `SubscribeUseCase`
/// at the CTA (Commit 5).
class PackagePurchaseCubit extends Cubit<PackagePurchaseState> with SafeEmit<PackagePurchaseState> {
  final ValidateCodeUseCase _validateCode;
  final PurchasePackageUseCase _purchasePackage;
  final RestorePurchasesUseCase _restorePurchases;
  final CurrentSubscriptionCubit _currentSubscription;

  PackagePurchaseCubit({
    required ValidateCodeUseCase validateCode,
    required PurchasePackageUseCase purchasePackage,
    required RestorePurchasesUseCase restorePurchases,
    required CurrentSubscriptionCubit currentSubscription,
  })  : _validateCode = validateCode,
        _purchasePackage = purchasePackage,
        _restorePurchases = restorePurchases,
        _currentSubscription = currentSubscription,
        super(const PackagePurchaseIdle());

  /// Validates [code] against [productId] for the current platform. Emits
  /// [PackagePurchaseValidatingCode] then success/failure.
  ///
  /// Both failure branches carry a locale KEY, never the server's own text.
  /// `message` on this endpoint is prose — the display site translates what it
  /// is handed, so prose arriving there is shown verbatim: right in Arabic by
  /// luck, and Arabic in an English UI.
  ///
  /// The two branches stay separate on purpose. A rejected code and a request
  /// that never got an answer are different facts, and on a payment path
  /// telling someone their code is wrong when the network failed is a lie the
  /// member acts on.
  ///
  /// Each refusal says which it was — wrong, expired, used up, or not
  /// applicable right now — from the server's errorCode ([DiscountCodeKeys],
  /// B3); never from the prose.
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
      // The request itself failed. `failure.message` is whatever the server or
      // transport said, so it is logged and dropped rather than shown.
      (failure) {
        AppLogger.warning(
          'VALIDATE CODE failed — serverMessage="${failure.message}"',
          tag: 'SUBSCRIPTIONS',
        );
        emit(
          PackagePurchaseCodeValidationFailure(
            message: DiscountCodeKeys.failed(failure),
          ),
        );
      },
      (response) => emit(
        response.valid
            ? PackagePurchaseCodeValidationSuccess(response: response)
            : PackagePurchaseCodeValidationFailure(
                message: DiscountCodeKeys.rejected(response.errorCode),
              ),
      ),
    );
  }

  /// Buys [pricing]. [validatedCode] carries an applied offer; [oldProductId]
  /// (a different owned product) drives an upgrade.
  Future<void> purchase({
    required SubscriptionPricing pricing,
    ValidateCodeResponse? validatedCode,
    String? oldProductId,
  }) async {
    // `productId` already resolves canonical-then-platform; no further fallback
    // — dropping to the Google id on iOS would look up a product the StoreKit
    // offering does not contain.
    final productId = pricing.productId(isIOS: Platform.isIOS);
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
    result.fold(
      _emitFailure,
      (info) => _onStoreConfirmed(info, restore: false),
    );
  }

  /// Restores prior purchases; an active one waits for the server like a
  /// purchase.
  Future<void> restorePurchases() async {
    emit(const PackagePurchaseInProgress());
    final result = await _restorePurchases();
    if (isClosed) return;
    result.fold(_emitFailure, (info) => _onStoreConfirmed(info, restore: true));
  }

  /// Back to the resting state — e.g. when the user clears a code or dismisses
  /// an error.
  void reset() => emit(const PackagePurchaseIdle());

  /// The store confirmed: «اشتراكي» says "activating" until the server does
  /// (C5). The app-scoped [CurrentSubscriptionCubit] does the re-reading, so
  /// the wait outlives this screen. A restore that found nothing active
  /// confirmed nothing.
  void _onStoreConfirmed(CustomerInfo info, {required bool restore}) {
    final active = info.entitlements.active
        .containsKey(RevenueCatConfig.premiumEntitlementId);
    if (!restore || active) {
      unawaited(_currentSubscription.onStoreConfirmed());
    }
    emit(PackagePurchaseSuccess(customerInfo: info));
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
}
