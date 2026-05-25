import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/services/payment_gateway.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../domain/entities/subscription_pricing.dart';
import '../../../domain/usecases/subscribe_usecase.dart';
import '../../../domain/usecases/validate_discount_code_usecase.dart';
import 'subscription_purchase_state.dart';

/// State machine for the purchase flow:
///
///   idle
///    ├── apply discount   → validating ─→ idle(discount?) | invalid
///    └── confirm purchase → awaitingPayment ─→ subscribing | idle
///                                              ├─→ success
///                                              └─→ failure
///
/// `/subscribe` is **only** called after [PaymentGateway] returns
/// [PaymentResultStatus.success]. Cancellation / failure short-circuits
/// back to idle so the user can retry without losing the discount.
class SubscriptionPurchaseCubit extends Cubit<SubscriptionPurchaseState> {
  final SubscriptionPricing _pricing;
  final ValidateDiscountCodeUseCase _validateDiscount;
  final SubscribeUseCase _subscribe;
  final PaymentGateway _paymentGateway;

  SubscriptionPurchaseCubit({
    required SubscriptionPricing pricing,
    required ValidateDiscountCodeUseCase validateDiscount,
    required SubscribeUseCase subscribe,
    required PaymentGateway paymentGateway,
  })  : _pricing = pricing,
        _validateDiscount = validateDiscount,
        _subscribe = subscribe,
        _paymentGateway = paymentGateway,
        super(const SubscriptionPurchaseIdle());

  /// The price the user actually pays — `discount.finalPrice` when an
  /// applied discount is valid, otherwise the pricing's own `price`.
  double get effectivePrice {
    final d = state.discount;
    if (d != null && d.isValid) return d.finalPrice;
    return _pricing.price;
  }

  /// Stores the user's pending input so a state change doesn't erase
  /// it. Does not validate.
  void onDiscountInputChanged(String value) {
    final input = value.trim().toUpperCase();
    if (input == state.discountInput) return;
    final s = state;
    emit(
      s is SubscriptionPurchaseDiscountInvalid
          ? SubscriptionPurchaseIdle(discountInput: input)
          : _withInput(s, input),
    );
  }

  /// Validates [code] against the current `pricingId`.
  Future<void> applyDiscount() async {
    final code = state.discountInput.trim();
    if (code.isEmpty) return;
    emit(SubscriptionPurchaseValidatingDiscount(
      discount: state.discount,
      discountInput: code,
    ));
    final result = await _validateDiscount(
      code: code,
      pricingId: _pricing.id,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(SubscriptionPurchaseDiscountInvalid(
        message: failure.message,
        discountInput: code,
      )),
      (validation) {
        if (validation.isValid) {
          emit(SubscriptionPurchaseIdle(
            discount: validation,
            discountInput: code,
          ));
        } else {
          emit(SubscriptionPurchaseDiscountInvalid(
            message: LocaleKeys.subscriptions_discount_invalid,
            discountInput: code,
          ));
        }
      },
    );
  }

  /// Clears any applied discount AND the entered code.
  void removeDiscount() {
    emit(const SubscriptionPurchaseIdle());
  }

  /// Drives payment → on success, calls `/subscribe`. Cancellation by
  /// the user returns to idle silently. Failures emit
  /// [SubscriptionPurchaseFailure].
  Future<void> confirmPurchase() async {
    // Don't burn an HTTP call if we're already mid-flight.
    final s = state;
    if (s is SubscriptionPurchaseAwaitingPayment ||
        s is SubscriptionPurchaseSubscribing) {
      return;
    }
    final activeDiscount = state.discount;
    final code = (activeDiscount != null && activeDiscount.isValid)
        ? state.discountInput
        : null;

    emit(SubscriptionPurchaseAwaitingPayment(
      discount: activeDiscount,
      discountInput: state.discountInput,
    ));

    final paymentResult = await _paymentGateway.payForPricing(
      pricing: _pricing,
      finalAmount: effectivePrice,
      discountCode: code,
    );
    if (isClosed) return;

    switch (paymentResult.status) {
      case PaymentResultStatus.cancelled:
        emit(SubscriptionPurchaseIdle(
          discount: activeDiscount,
          discountInput: state.discountInput,
        ));
        return;
      case PaymentResultStatus.failed:
        emit(SubscriptionPurchaseFailure(
          message: paymentResult.errorMessage ??
              LocaleKeys.subscriptions_subscribe_failed,
          discount: activeDiscount,
          discountInput: state.discountInput,
        ));
        return;
      case PaymentResultStatus.success:
        // Continue below — only after explicit success do we hit /subscribe.
        break;
    }

    emit(SubscriptionPurchaseSubscribing(
      discount: activeDiscount,
      discountInput: state.discountInput,
    ));
    final result = await _subscribe(
      pricingId: _pricing.id,
      discountCode: code,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(SubscriptionPurchaseFailure(
        message: failure.message,
        discount: activeDiscount,
        discountInput: state.discountInput,
      )),
      (subscription) => emit(SubscriptionPurchaseSuccess(
        subscription: subscription,
        discount: activeDiscount,
        discountInput: state.discountInput,
      )),
    );
  }

  /// Type-preserving "withInput" for [SubscriptionPurchaseState] — keeps
  /// the current concrete state so a typed `switch` upstream stays
  /// exhaustive.
  SubscriptionPurchaseState _withInput(
    SubscriptionPurchaseState s,
    String input,
  ) {
    return switch (s) {
      SubscriptionPurchaseIdle() =>
        SubscriptionPurchaseIdle(discount: s.discount, discountInput: input),
      SubscriptionPurchaseValidatingDiscount() =>
        SubscriptionPurchaseValidatingDiscount(
          discount: s.discount,
          discountInput: input,
        ),
      SubscriptionPurchaseDiscountInvalid() =>
        SubscriptionPurchaseDiscountInvalid(
          message: s.message,
          discountInput: input,
        ),
      SubscriptionPurchaseAwaitingPayment() =>
        SubscriptionPurchaseAwaitingPayment(
          discount: s.discount,
          discountInput: input,
        ),
      SubscriptionPurchaseSubscribing() =>
        SubscriptionPurchaseSubscribing(
          discount: s.discount,
          discountInput: input,
        ),
      SubscriptionPurchaseSuccess() => SubscriptionPurchaseSuccess(
          subscription: s.subscription,
          discount: s.discount,
          discountInput: input,
        ),
      SubscriptionPurchaseFailure() => SubscriptionPurchaseFailure(
          message: s.message,
          discount: s.discount,
          discountInput: input,
        ),
    };
  }
}
