import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/affiliate_summary.dart';

/// Wire model for `GET /affiliate/summary`. Field names are the expected
/// camelCase keys — confirm against the live payload (Tariq) before launch;
/// the defensive parsers tolerate int↔string / null drift so one misaligned
/// key never collapses the screen.
class AffiliateSummaryModel {
  final String referralCode;
  final int referredUsersCount;
  final int registeredUsersCount;
  final int codeUsedCount;
  final double totalCommission;
  final double pendingCommission;
  final double paidCommission;
  final String currency;

  const AffiliateSummaryModel({
    required this.referralCode,
    required this.referredUsersCount,
    required this.registeredUsersCount,
    required this.codeUsedCount,
    required this.totalCommission,
    required this.pendingCommission,
    required this.paidCommission,
    required this.currency,
  });

  factory AffiliateSummaryModel.fromJson(Map<String, dynamic> json) =>
      AffiliateSummaryModel(
        referralCode: parseString(json['referralCode']),
        referredUsersCount: parseInt(json['referredUsersCount']),
        registeredUsersCount: parseInt(json['registeredUsersCount']),
        codeUsedCount: parseInt(json['codeUsedCount']),
        totalCommission: parseDouble(json['totalCommission']),
        pendingCommission: parseDouble(json['pendingCommission']),
        paidCommission: parseDouble(json['paidCommission']),
        currency: parseString(json['currency'], fallback: 'USD'),
      );

  AffiliateSummary toEntity() => AffiliateSummary(
        referralCode: referralCode,
        referredUsersCount: referredUsersCount,
        registeredUsersCount: registeredUsersCount,
        codeUsedCount: codeUsedCount,
        totalCommission: totalCommission,
        pendingCommission: pendingCommission,
        paidCommission: paidCommission,
        currency: currency,
      );
}
