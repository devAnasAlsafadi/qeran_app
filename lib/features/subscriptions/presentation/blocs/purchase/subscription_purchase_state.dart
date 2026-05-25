import 'package:equatable/equatable.dart';

import '../../../domain/entities/current_subscription.dart';
import '../../../domain/entities/discount_validation.dart';

sealed class SubscriptionPurchaseState extends Equatable {
  /// Currently-applied discount (or `null` when none / cleared). Held on
  /// the base class so every state branch keeps it without copying.
  final DiscountValidation? discount;

  /// Latest text entered into the discount field — preserved across
  /// state transitions so the screen doesn't lose user input on a
  /// rebuild.
  final String discountInput;

  const SubscriptionPurchaseState({
    this.discount,
    this.discountInput = '',
  });

  @override
  List<Object?> get props => [discount, discountInput];
}

/// Idle / waiting for user input.
final class SubscriptionPurchaseIdle extends SubscriptionPurchaseState {
  const SubscriptionPurchaseIdle({super.discount, super.discountInput});
}

/// Validating the entered discount code against `pricingId`.
final class SubscriptionPurchaseValidatingDiscount
    extends SubscriptionPurchaseState {
  const SubscriptionPurchaseValidatingDiscount({
    super.discount,
    super.discountInput,
  });
}

/// The last `apply` produced `isValid: false`. UI shows a hint;
/// `discount` is null so the price summary reverts to the pricing's
/// original `price`.
final class SubscriptionPurchaseDiscountInvalid
    extends SubscriptionPurchaseState {
  final String message;
  const SubscriptionPurchaseDiscountInvalid({
    required this.message,
    super.discountInput,
  });

  @override
  List<Object?> get props => [message, ...super.props];
}

/// Payment is being driven through the [PaymentGateway].
final class SubscriptionPurchaseAwaitingPayment
    extends SubscriptionPurchaseState {
  const SubscriptionPurchaseAwaitingPayment({
    super.discount,
    super.discountInput,
  });
}

/// Payment succeeded, `/subscribe` is in flight.
final class SubscriptionPurchaseSubscribing
    extends SubscriptionPurchaseState {
  const SubscriptionPurchaseSubscribing({
    super.discount,
    super.discountInput,
  });
}

/// `/subscribe` succeeded; carries the new `CurrentSubscription` so
/// the screen can update `CurrentSubscriptionCubit` and pop.
final class SubscriptionPurchaseSuccess extends SubscriptionPurchaseState {
  final CurrentSubscription subscription;
  const SubscriptionPurchaseSuccess({
    required this.subscription,
    super.discount,
    super.discountInput,
  });

  @override
  List<Object?> get props => [subscription, ...super.props];
}

/// `/subscribe` failed (or payment failed). Single human-readable
/// message routed to a SnackBar / inline hint.
final class SubscriptionPurchaseFailure extends SubscriptionPurchaseState {
  final String message;
  const SubscriptionPurchaseFailure({
    required this.message,
    super.discount,
    super.discountInput,
  });

  @override
  List<Object?> get props => [message, ...super.props];
}
