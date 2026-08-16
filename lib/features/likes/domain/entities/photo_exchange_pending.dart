import 'package:equatable/equatable.dart';

import '../../../../core/utils/server_clock.dart';
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

  /// Still genuinely open.
  ///
  /// ⚠️ Read [status] — never the presence of [expiresAt]. `/api/matches` is
  /// the endpoint where that distinction bites hardest: Tariq confirmed it
  /// returns a non-null `pendingPhotoExchange.expiresAt` even for requests
  /// that have already lapsed, so the block being present, and its deadline
  /// being non-null, say nothing about whether anyone can still act. The
  /// status plus the comparison are the whole answer.
  ///
  /// [canAccept] / [canReject] remain the authority for the BUTTONS — the
  /// server also weighs whose turn it is. This getter governs what the row
  /// claims about itself.
  bool get isAwaitingResponse =>
      status == PhotoExchangeStatus.pending && !hasServerExpired(expiresAt);

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
