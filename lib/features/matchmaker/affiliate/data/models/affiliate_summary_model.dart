import 'package:qeran/core/app_logger.dart';

import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/affiliate_commission_type.dart';
import '../../domain/entities/affiliate_summary.dart';

/// Wire model for `GET /affiliate/summary`. Field names are the live (Tariq)
/// camelCase keys; the defensive parsers tolerate int↔string / null drift so
/// one misaligned key never collapses the screen.
class AffiliateSummaryModel {
  final String referralCode;
  final double? commissionRate;
  final AffiliateCommissionType? commissionType;
  final int referredUsersCount;
  final int registeredUsersCount;
  final int codeUsedCount;
  final double totalCommission;
  final double pendingCommission;
  final double paidCommission;
  final String currency;

  const AffiliateSummaryModel({
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

  factory AffiliateSummaryModel.fromJson(Map<String, dynamic> json) =>
      AffiliateSummaryModel(
        referralCode: parseString(json['referralCode']),
        commissionRate: parseNullableDouble(json['commissionRate']),
        commissionType: _parseType(json['commissionType']),
        referredUsersCount: parseInt(json['referredUsersCount']),
        registeredUsersCount: parseInt(json['registeredUsersCount']),
        codeUsedCount: parseInt(json['codeUsedCount']),
        totalCommission: parseDouble(json['totalCommission']),
        pendingCommission: parseDouble(json['pendingCommission']),
        paidCommission: parseDouble(json['paidCommission']),
        currency: parseString(json['currency'], fallback: 'USD'),
      );

  /// Case-insensitive map into the contract's two rate kinds. An absent or
  /// unrecognised value resolves to `null` (never fabricated) so the UI renders
  /// the rate forward-safely; a genuinely unknown non-empty value is logged.
  static AffiliateCommissionType? _parseType(Object? raw) {
    final value = parseNullableString(raw)?.trim().toLowerCase();
    switch (value) {
      case null:
      case '':
        return null;
      case 'percent':
        return AffiliateCommissionType.percent;
      case 'fixed':
        return AffiliateCommissionType.fixed;
      default:
        AppLogger.warning(
          'AFFILIATE — unknown commissionType "$raw" → null',
          tag: 'AFFILIATE',
        );
        return null;
    }
  }

  AffiliateSummary toEntity() => AffiliateSummary(
        referralCode: referralCode,
        commissionRate: commissionRate,
        commissionType: commissionType,
        referredUsersCount: referredUsersCount,
        registeredUsersCount: registeredUsersCount,
        codeUsedCount: codeUsedCount,
        totalCommission: totalCommission,
        pendingCommission: pendingCommission,
        paidCommission: paidCommission,
        currency: currency,
      );
}
