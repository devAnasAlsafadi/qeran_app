import 'package:equatable/equatable.dart';

/// Result of `GET /api/subscriptions/discount-codes/{code}/validate?pricingId=X`.
/// Always succeeds at the HTTP level — invalid codes are encoded inside
/// `isValid: false`, not as failures.
class DiscountValidation extends Equatable {
  final bool isValid;
  final double discountRate;
  final double originalPrice;
  final double finalPrice;

  const DiscountValidation({
    required this.isValid,
    required this.discountRate,
    required this.originalPrice,
    required this.finalPrice,
  });

  /// Sentinel for a failed/empty validation — used by cubits as the
  /// initial state, distinct from "valid but 0% discount".
  static const DiscountValidation invalid = DiscountValidation(
    isValid: false,
    discountRate: 0,
    originalPrice: 0,
    finalPrice: 0,
  );

  @override
  List<Object?> get props =>
      [isValid, discountRate, originalPrice, finalPrice];
}
