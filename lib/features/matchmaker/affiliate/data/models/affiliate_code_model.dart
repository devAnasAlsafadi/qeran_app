import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/affiliate_code.dart';

/// Wire model for one entry of the `codes` list on `GET /affiliate/summary`.
///
/// Parses ONLY the six fields the dashboard renders. The payload also carries
/// `isActive`, `expiresAt` and `maxUsageCount`, deliberately left alone: the
/// backend puts only currently-valid codes in this list, so they would be
/// fields nothing reads.
class AffiliateCodeModel {
  final String code;
  final bool isPrimary;
  final double discountPercent;
  final double commissionRate;
  final int codeUsedCount;
  final double totalCommission;

  const AffiliateCodeModel({
    required this.code,
    required this.isPrimary,
    required this.discountPercent,
    required this.commissionRate,
    required this.codeUsedCount,
    required this.totalCommission,
  });

  factory AffiliateCodeModel.fromJson(Map<String, dynamic> json) =>
      AffiliateCodeModel(
        code: parseString(json['code']),
        isPrimary: parseBool(json['isPrimary']),
        discountPercent: parseDouble(json['discountPercent']),
        commissionRate: parseDouble(json['commissionRate']),
        codeUsedCount: parseInt(json['codeUsedCount']),
        totalCommission: parseDouble(json['totalCommission']),
      );

  AffiliateCode toEntity() => AffiliateCode(
        code: code,
        isPrimary: isPrimary,
        discountPercent: discountPercent,
        commissionRate: commissionRate,
        codeUsedCount: codeUsedCount,
        totalCommission: totalCommission,
      );
}
