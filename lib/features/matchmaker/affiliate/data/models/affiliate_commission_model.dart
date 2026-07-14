import 'package:qeran/core/app_logger.dart';

import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/affiliate_commission.dart';
import '../../domain/entities/affiliate_commission_status.dart';

/// Wire model for one commission-ledger row. Field names are the expected
/// camelCase keys — confirm against the live payload (Tariq) before launch.
class AffiliateCommissionModel {
  final DateTime? date;
  final String userDisplay;
  final String planName;
  final String discountCode;
  final double amount;
  final String currency;
  final AffiliateCommissionStatus status;

  const AffiliateCommissionModel({
    required this.date,
    required this.userDisplay,
    required this.planName,
    required this.discountCode,
    required this.amount,
    required this.currency,
    required this.status,
  });

  factory AffiliateCommissionModel.fromJson(Map<String, dynamic> json) =>
      AffiliateCommissionModel(
        date: parseNullableDateTime(json['date']),
        userDisplay: parseString(json['userDisplay']),
        planName: parseString(json['planName']),
        discountCode: parseString(json['discountCode']),
        amount: parseDouble(json['amount']),
        currency: parseString(json['currency'], fallback: 'USD'),
        status: _parseStatus(json['status']),
      );

  /// Case-insensitive map into the three contract states. An absent or
  /// unrecognised value keeps the row visible (never hide a money line) and
  /// falls back to [AffiliateCommissionStatus.pending] — the neutral,
  /// not-yet-settled state — while logging the drift for follow-up.
  static AffiliateCommissionStatus _parseStatus(Object? raw) {
    final value = parseNullableString(raw)?.trim().toLowerCase();
    switch (value) {
      case 'pending':
        return AffiliateCommissionStatus.pending;
      case 'confirmed':
        return AffiliateCommissionStatus.confirmed;
      case 'reversed':
        return AffiliateCommissionStatus.reversed;
      default:
        AppLogger.warning(
          'AFFILIATE — unknown commission status "$raw" → pending',
          tag: 'AFFILIATE',
        );
        return AffiliateCommissionStatus.pending;
    }
  }

  AffiliateCommission toEntity() => AffiliateCommission(
        date: date,
        userDisplay: userDisplay,
        planName: planName,
        discountCode: discountCode,
        amount: amount,
        currency: currency,
        status: status,
      );
}
