import 'package:equatable/equatable.dart';

import 'affiliate_code.dart';
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

  /// Every code this matchmaker holds, each with its OWN usage count and
  /// earnings. Empty when the backend sends no list — never null, so callers
  /// never branch on absence.
  ///
  /// The account-level fields above are the SUM across these, which is why the
  /// dashboard must not show them under one code's name.
  final List<AffiliateCode> codes;

  /// ISO currency code for every money field. Backend field — today always
  /// `USD` (confirmed contract decision), but the app always displays whatever
  /// the backend sends, never a hardcoded literal.
  final String currency;

  const AffiliateSummary({
    required this.referralCode,
    this.codes = const [],
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

  /// Redemptions summed across [codes].
  int get codesUsedSum =>
      codes.fold(0, (total, code) => total + code.codeUsedCount);

  /// Earnings summed across [codes].
  double get codesCommissionSum =>
      codes.fold(0, (total, code) => total + code.totalCommission);

  /// Whether the per-code figures add up to the account totals.
  ///
  /// True when there is nothing to check — an empty list is not a
  /// disagreement. A false here is a BACKEND data fault (stored counters out
  /// of step with the referral rows), not a display one: the app shows what it
  /// is sent either way, and the cubit logs so the drift is visible on the
  /// device the moment it appears rather than surfacing as a wrong number.
  ///
  /// Money is compared with a TOLERANCE, not equality. Adding doubles does not
  /// always land on the decimal value written down (`0.1 + 0.2` is famously
  /// `0.30000000000000004`), so an `==` here would report drift on payloads
  /// that are perfectly correct — and a warning that cries wolf is one nobody
  /// reads. Half a cent is far below anything the UI can render and far above
  /// float noise.
  ///
  /// Today's live figures happen to add up exactly, which is luck about those
  /// particular values and not something to rely on.
  bool get codesReconcile {
    if (codes.isEmpty) return true;
    return codesUsedSum == codeUsedCount &&
        (codesCommissionSum - totalCommission).abs() < 0.005;
  }

  @override
  List<Object?> get props => [
        referralCode,
        codes,
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
