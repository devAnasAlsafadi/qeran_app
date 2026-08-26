import '../../domain/entities/formal_step_status.dart';
import '../../domain/entities/pending_formal_step.dart';
import '../json_parsers.dart';

/// Wire model for the `pendingFormalStep` block on a `/api/matches` row.
///
/// `createdAt` and `expiresAt` stay NULLABLE here, unlike the photo-exchange
/// model which substitutes epoch zero for a missing date. Epoch zero is a real
/// timestamp in the deep past, so it reads as "already expired" — harmless for
/// a block that only ever appears while Pending, but a lie the expiry check
/// would repeat. Null says "no deadline known", which `hasServerExpired`
/// answers correctly on its own.
class PendingFormalStepModel {
  final int id;
  final int likeRequestId;
  final String status;
  final int? remainingSeconds;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final String direction;
  final bool requestedByMe;
  final bool canAccept;
  final bool canReject;

  const PendingFormalStepModel({
    required this.id,
    required this.likeRequestId,
    required this.status,
    required this.remainingSeconds,
    required this.createdAt,
    required this.expiresAt,
    required this.direction,
    required this.requestedByMe,
    required this.canAccept,
    required this.canReject,
  });

  /// Returns null when [raw] isn't a Map — the block is absent whenever no
  /// request is open, which is most of the time.
  static PendingFormalStepModel? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return PendingFormalStepModel(
      id: parseInt(raw['id']),
      likeRequestId: parseInt(raw['likeRequestId']),
      status: parseString(raw['status']),
      remainingSeconds: parseNullableInt(raw['remainingSeconds']),
      createdAt: parseNullableDateTime(raw['createdAt']),
      expiresAt: parseNullableDateTime(raw['expiresAt']),
      direction: parseString(raw['direction']),
      requestedByMe: parseBool(raw['requestedByMe']),
      canAccept: parseBool(raw['canAccept']),
      canReject: parseBool(raw['canReject']),
    );
  }

  PendingFormalStep toEntity() => PendingFormalStep(
        id: id,
        likeRequestId: likeRequestId,
        status: FormalStepStatus.fromString(status),
        remainingSeconds: remainingSeconds,
        createdAt: createdAt,
        expiresAt: expiresAt,
        direction: direction,
        requestedByMe: requestedByMe,
        canAccept: canAccept,
        canReject: canReject,
      );
}
