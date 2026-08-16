import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/case_photo_exchange.dart';
import '../../domain/entities/case_photo_exchange_status.dart';

/// Wire model for the nullable `photoExchange` sub-object. `initiatorId` /
/// `responderId` are newly-added nullable fields (absent from the current
/// payload → parse to `null`).
class CasePhotoExchangeModel {
  final int requestId;
  final String status;
  final DateTime? respondedAt;
  final DateTime? expiresAt;
  final String? initiatorId;
  final String? responderId;

  const CasePhotoExchangeModel({
    required this.requestId,
    required this.status,
    required this.respondedAt,
    required this.initiatorId,
    required this.responderId,
    this.expiresAt,
  });

  factory CasePhotoExchangeModel.fromJson(Map<String, dynamic> json) =>
      CasePhotoExchangeModel(
        requestId: parseInt(json['requestId']),
        status: parseString(json['status']),
        respondedAt: parseNullableDateTime(json['respondedAt']),
        // Absent on payloads predating the field — parses to null, which the
        // entity reads as "no deadline", not as "expired".
        expiresAt: parseNullableDateTime(json['expiresAt']),
        initiatorId: parseNullableString(json['initiatorId']),
        responderId: parseNullableString(json['responderId']),
      );

  CasePhotoExchange toEntity() => CasePhotoExchange(
    requestId: requestId,
    status: CasePhotoExchangeStatus.fromString(status),
    respondedAt: respondedAt,
    expiresAt: expiresAt,
    initiatorId: initiatorId,
    responderId: responderId,
  );
}
