import 'package:equatable/equatable.dart';

import 'photo_exchange_direction.dart';
import 'photo_exchange_status.dart';

/// One in-flight photo-exchange request attached to a match.
///
/// Driven by the server's `pendingPhotoExchange` block — present only
/// when there's a Pending request. `canAccept`/`canReject` are the
/// authoritative UI gates; `direction` and `requestedByMe` are
/// informational but help log meaningfully.
class PhotoExchangePending extends Equatable {
  final int id;
  final int likeRequestId;
  final String initiatorId;
  final String responderId;
  final PhotoExchangeStatus status;
  final int statusCode;
  final int? remainingSeconds;
  final DateTime createdAt;
  final DateTime expiresAt;
  final PhotoExchangeDirection direction;
  final bool requestedByMe;
  final bool canAccept;
  final bool canReject;

  const PhotoExchangePending({
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

  @override
  List<Object?> get props => [
        id,
        likeRequestId,
        initiatorId,
        responderId,
        status,
        statusCode,
        remainingSeconds,
        createdAt,
        expiresAt,
        direction,
        requestedByMe,
        canAccept,
        canReject,
      ];
}
