import 'package:equatable/equatable.dart';

/// One discount code belonging to a matchmaker, from the `codes` list on
/// `GET /affiliate/summary`.
///
/// A matchmaker can hold several — a permanent one plus campaign codes — and
/// the account-level totals on [AffiliateSummary] are the SUM across all of
/// them. Before this list existed the dashboard named one code and showed
/// those sums beneath it, so a second code's earnings read as the first one's.
///
/// ⚠️ [discountPercent] and [commissionRate] are different people's money and
/// must never be presented alike. The first is what the BUYER saves; the
/// second is the matchmaker's cut. A code can give 50% off while earning her
/// 10% — showing the 50 as earnings overstates her income fivefold.
///
/// Carries no pending/paid split by design: settlement happens once at the
/// account level with no per-referral record, so any per-code pending figure
/// would be invented.
class AffiliateCode extends Equatable {
  /// The code itself, as the member types it at checkout.
  final String code;

  /// The matchmaker's permanent code — the one `referralCode` also returns and
  /// the only one the account screen offers for sharing.
  final bool isPrimary;

  /// What the BUYER saves with this code. Never the matchmaker's earnings.
  final double discountPercent;

  /// The matchmaker's cut on subscriptions bought with this code. Normally
  /// equal to her account rate; the backend supports a per-code override.
  final double commissionRate;

  /// Redemptions on a subscription with this code.
  final int codeUsedCount;

  /// Lifetime commission earned through this code, in the summary's currency.
  final double totalCommission;

  const AffiliateCode({
    required this.code,
    required this.isPrimary,
    required this.discountPercent,
    required this.commissionRate,
    required this.codeUsedCount,
    required this.totalCommission,
  });

  @override
  List<Object?> get props => [
        code,
        isPrimary,
        discountPercent,
        commissionRate,
        codeUsedCount,
        totalCommission,
      ];
}
