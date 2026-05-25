import '../../features/subscriptions/domain/entities/subscription_pricing.dart';

/// Outcome of an attempted payment. Mobile must only call `/subscribe`
/// when [PaymentResultStatus.success] is returned.
enum PaymentResultStatus { success, cancelled, failed }

class PaymentResult {
  final PaymentResultStatus status;

  /// Optional gateway-side reference (`txn_id`, receipt, etc.).
  /// Forwarded to telemetry when present; not required by the API yet.
  final String? gatewayRef;

  /// Optional human-readable failure message for `failed`.
  final String? errorMessage;

  const PaymentResult({
    required this.status,
    this.gatewayRef,
    this.errorMessage,
  });

  const PaymentResult.success({this.gatewayRef})
      : status = PaymentResultStatus.success,
        errorMessage = null;

  const PaymentResult.cancelled()
      : status = PaymentResultStatus.cancelled,
        gatewayRef = null,
        errorMessage = null;

  const PaymentResult.failed({required String message})
      : status = PaymentResultStatus.failed,
        gatewayRef = null,
        errorMessage = message;
}

/// One-method abstraction over whatever payment surface the app uses.
/// Today this is a development-only stub (`FakePaymentGateway`); when
/// the real gateway lands (In-App Purchase, MyFatoorah, …) we swap the
/// implementation without touching the purchase cubit, screen, or repo.
abstract interface class PaymentGateway {
  /// Drive the user through the payment UI for [pricing] at
  /// [finalAmount] (which may differ from `pricing.price` when a
  /// discount is applied). Must NEVER call `/subscribe` directly; the
  /// caller (`SubscriptionPurchaseCubit`) is responsible for that and
  /// only does so on [PaymentResultStatus.success].
  Future<PaymentResult> payForPricing({
    required SubscriptionPricing pricing,
    required double finalAmount,
    String? discountCode,
  });
}
