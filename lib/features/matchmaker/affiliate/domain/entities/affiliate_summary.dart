import 'package:equatable/equatable.dart';

/// The matchmaker's affiliate dashboard header (`GET /affiliate/summary`): their
/// share code plus referral counts and commission earnings split by settlement
/// state. All money is in [currency]. A 404 from the endpoint is NOT this — it
/// means the matchmaker isn't enrolled (see `AffiliateNotEnrolledFailure`).
class AffiliateSummary extends Equatable {
  /// The matchmaker's own referral/share code.
  final String referralCode;

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

  /// ISO currency code for every money field (e.g. `SAR`).
  final String currency;

  const AffiliateSummary({
    required this.referralCode,
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
        referredUsersCount,
        registeredUsersCount,
        codeUsedCount,
        totalCommission,
        pendingCommission,
        paidCommission,
        currency,
      ];
}
