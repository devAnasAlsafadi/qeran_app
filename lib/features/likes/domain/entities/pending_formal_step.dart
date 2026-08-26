import 'package:equatable/equatable.dart';

import '../../../../core/utils/server_clock.dart';
import 'formal_step_status.dart';

/// One in-flight formal-step request attached to a match.
///
/// Driven by the server's `pendingFormalStep` block — the formal-step twin of
/// `pendingPhotoExchange`, and deliberately the same shape so the receiver's
/// card can work the way the photo-exchange one already does: the SAME request
/// is returned to both members, and [canAccept] / [canReject] are computed by
/// the server relative to whoever asked. The client never works out whose turn
/// it is.
///
/// Three fields the photo-exchange block has are absent here: `initiatorId`,
/// `responderId`, and the numeric `statusCode`. [direction] is kept as the raw
/// string rather than an enum because nothing branches on it — it is
/// diagnostic, and [requestedByMe] already answers the only question the UI
/// asks of it.
class PendingFormalStep extends Equatable {
  final int id;
  final int likeRequestId;
  final FormalStepStatus status;
  final int? remainingSeconds;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  /// `"Sent"` / `"Received"` from the caller's perspective. Logged, never
  /// branched on — see the class doc.
  final String direction;

  final bool requestedByMe;
  final bool canAccept;
  final bool canReject;

  const PendingFormalStep({
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

  /// Still genuinely open.
  ///
  /// ⚠️ Reads [status] AND the clock — never the presence of [expiresAt]. The
  /// matches feed returns a real deadline for photo-exchange requests that have
  /// already lapsed, and a lapsed request keeps its Pending status until the
  /// server sweeps it, so neither signal is sufficient alone. Whether the
  /// formal step repeats that behaviour is unconfirmed; answering the same way
  /// costs nothing if it does not, and is the difference between a live
  /// countdown and a dead one if it does.
  ///
  /// [canAccept] / [canReject] remain the authority for the BUTTONS — the
  /// server also weighs whose turn it is. This getter governs what the row
  /// claims about itself.
  bool get isAwaitingResponse =>
      status == FormalStepStatus.pending && !hasServerExpired(expiresAt);

  @override
  List<Object?> get props => [
        id,
        likeRequestId,
        status,
        remainingSeconds,
        createdAt,
        expiresAt,
        direction,
        requestedByMe,
        canAccept,
        canReject,
      ];
}
