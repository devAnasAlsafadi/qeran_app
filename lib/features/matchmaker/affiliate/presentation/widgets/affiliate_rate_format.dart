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

/// The commission rate to show on ONE code's row, or `null` when there is
/// nothing worth saying.
///
/// A code normally earns the matchmaker her account rate, and repeating `10%`
/// on every row would say nothing while competing for attention with the
/// buyer's discount sitting beside it — the one number on that row that means
/// somebody else's money. So the rate appears only when the backend has set a
/// per-code override and it genuinely differs.
///
/// Returns `null` for an equal rate, and also when the account rate is unknown:
/// with nothing to compare against, "differs" is not a claim we can make.
String? formatPerCodeRate(
  double codeRate,
  double? accountRate,
  AffiliateCommissionType? type,
  String currency,
) {
  if (accountRate == null || codeRate == accountRate) return null;
  return formatCommissionRate(codeRate, type, currency);
}
