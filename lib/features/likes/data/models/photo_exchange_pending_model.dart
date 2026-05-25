import '../../domain/entities/photo_exchange_direction.dart';
import '../../domain/entities/photo_exchange_pending.dart';
import '../../domain/entities/photo_exchange_status.dart';
import '../json_parsers.dart';

class PhotoExchangePendingModel {
  final int id;
  final int likeRequestId;
  final String initiatorId;
  final String responderId;
  final String status;
  final int statusCode;
  final int? remainingSeconds;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String direction;
  final bool requestedByMe;
  final bool canAccept;
  final bool canReject;

  const PhotoExchangePendingModel({
    required this.id,
    required this.likeRequestId,
    required this.initiatorId,
    required this.responderId,
    required this.status,
    required this.statusCode,
    required this.remainingSeconds,
    required this.createdAt,
    required this.expiresAt,
    required this.direction,
    required this.requestedByMe,
    required this.canAccept,
    required this.canReject,
  });

  /// Returns null when [raw] isn't a Map — defensive against a future
  /// server-side shape change. Every string field tolerates an int
  /// from the backend (the `status` and `direction` fields have been
  /// observed to flip between enum string and enum int).
  static PhotoExchangePendingModel? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return PhotoExchangePendingModel(
      id: parseInt(raw['id']),
      likeRequestId: parseInt(raw['likeRequestId']),
      initiatorId: parseString(raw['initiatorId']),
      responderId: parseString(raw['responderId']),
      status: parseString(raw['status']),
      statusCode: parseInt(raw['statusCode']),
      remainingSeconds: parseNullableInt(raw['remainingSeconds']),
      createdAt: parseNullableDateTime(raw['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      expiresAt: parseNullableDateTime(raw['expiresAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      direction: parseString(raw['direction']),
      requestedByMe: parseBool(raw['requestedByMe']),
      canAccept: parseBool(raw['canAccept']),
      canReject: parseBool(raw['canReject']),
    );
  }

  PhotoExchangePending toEntity() => PhotoExchangePending(
        id: id,
        likeRequestId: likeRequestId,
        initiatorId: initiatorId,
        responderId: responderId,
        status: PhotoExchangeStatus.fromCode(statusCode),
        statusCode: statusCode,
        remainingSeconds: remainingSeconds,
        createdAt: createdAt,
        expiresAt: expiresAt,
        direction: PhotoExchangeDirection.fromString(direction),
        requestedByMe: requestedByMe,
        canAccept: canAccept,
        canReject: canReject,
      );
}
