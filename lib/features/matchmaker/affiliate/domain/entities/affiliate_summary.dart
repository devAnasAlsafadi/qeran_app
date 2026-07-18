import 'package:equatable/equatable.dart';

import 'affiliate_commission_type.dart';

/// The matchmaker's affiliate dashboard header (`GET /affiliate/summary`): their
/// share code, commission rate, referral counts, and commission earnings split
/// by settlement state. All money is in [currency]. A 404 from the endpoint is
/// NOT this — it means the matchmaker isn't enrolled (see
/// `AffiliateNotEnrolledFailure`).
class AffiliateSummary extends Equatable {
  /// The matchmaker's own referral/share code.
  final String referralCode;

  /// The commission rate the project owner set for this matchmaker in the web
  /// dashboard. Null when no rate has been set yet — the UI shows a neutral `—`
  /// (never a fabricated value). Interpreted per [commissionType].
  final double? commissionRate;

  /// How [commissionRate] is expressed (percent today; fixed reserved). Null
  /// when the backend omits it or sends an unrecognised value.
  final AffiliateCommissionType? commissionType;

  /// How many users have entered this code at registration.
  final int referredUsersCount;

  /// Of the referred users, how many completed registration.
  final int registeredUsersCount;

  /// How many times the code has been redeemed on a subscription.
  final int codeUsedCount;

  /// Lifetime commission earned (all states summed).
  final double totalCommission;

  /// Commission earned but not yet settled/paid out.
  final double pendingCommission;

  /// Commission already paid out to the matchmaker.
  final double paidCommission;

  /// ISO currency code for every money field. Backend field — today always
  /// `USD` (confirmed contract decision), but the app always displays whatever
  /// the backend sends, never a hardcoded literal.
  final String currency;

  const AffiliateSummary({
    required this.referralCode,
    required this.commissionRate,
    required this.commissionType,
    required this.referredUsersCount,
    required this.registeredUsersCount,
    required this.codeUsedCount,
    required this.totalCommission,
    required this.pendingCommission,
    required this.paidCommission,
    required this.currency,
  });

  @override
  List<Object?> get props => [
        referralCode,
        commissionRate,
        commissionType,
        referredUsersCount,
        registeredUsersCount,
        codeUsedCount,
        totalCommission,
        pendingCommission,
        paidCommission,
        currency,
      ];
}
