import '../../domain/entities/affiliate_commission_type.dart';

/// Pure, locale-free formatter for the matchmaker's commission rate. Returns
/// `null` when [rate] is absent (the widget then shows a neutral `—`); it never
/// fabricates a value. Branches on [type] so the `%` is never unconditional:
///   • percent → `10%`
///   • fixed   → `10 USD`  (amount + [currency])
///   • unknown/null type (but a rate present) → `10` (bare, forward-safe)
/// Whole numbers drop the decimals; fractional values show two places.
String? formatCommissionRate(
  double? rate,
  AffiliateCommissionType? type,
  String currency,
) {
  if (rate == null) return null;
  final number = _formatNumber(rate);
  return switch (type) {
    AffiliateCommissionType.percent => '$number%',
    AffiliateCommissionType.fixed => '$number $currency',
    null => number,
  };
}

String _formatNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);
