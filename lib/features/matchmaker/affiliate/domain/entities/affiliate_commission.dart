import 'package:equatable/equatable.dart';

import 'affiliate_commission_status.dart';

/// One row of the matchmaker's commission ledger (`GET /affiliate/commissions`).
/// [userDisplay] is the backend's already-masked label for the referred user
/// (e.g. masked initials) — the app never de-masks or reconstructs identity.
/// [amount] is in [currency]. [date] is when the commission accrued.
class AffiliateCommission extends Equatable {
  final DateTime? date;
  final String userDisplay;
  final String planName;
  final String discountCode;
  final double amount;
  final String currency;
  final AffiliateCommissionStatus status;

  const AffiliateCommission({
    required this.date,
    required this.userDisplay,
    required this.planName,
    required this.discountCode,
    required this.amount,
    required this.currency,
    required this.status,
  });

  @override
  List<Object?> get props => [
        date,
        userDisplay,
        planName,
        discountCode,
        amount,
        currency,
        status,
      ];
}
