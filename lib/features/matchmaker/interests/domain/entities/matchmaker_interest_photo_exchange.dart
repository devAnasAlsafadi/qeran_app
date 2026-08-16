import 'package:equatable/equatable.dart';

import '../../../../../core/utils/server_clock.dart';
import 'matchmaker_interest_enums.dart';

/// The photo-exchange request attached to an active match, mirrored read-only.
///
/// The matchmaker watches this window; she does not act on it. All the card
/// needs is whether it is still running and until when.
class MatchmakerInterestPhotoExchange extends Equatable {
  final MatchmakerInterestPhotoExchangeStatus status;

  /// Deadline for the two members to respond. Nullable: the field is newer
  /// than this DTO's first shipment, so an older payload simply has none —
  /// which reads as "nothing to count down to", never as an expiry.
  final DateTime? expiresAt;

  /// The server's own view of the time left, when it sends one. Used to
  /// calibrate [ServerClock] rather than to drive the display.
  final int? remainingSeconds;

  const MatchmakerInterestPhotoExchange({
    required this.status,
    this.expiresAt,
    this.remainingSeconds,
  });

  /// Still genuinely open — the same status-AND-deadline rule the likes rows
  /// and the compatibility cases use. Status is read explicitly: the block
  /// keeps arriving, with a real deadline, after the window has closed, so
  /// its presence proves nothing.
  bool get isAwaitingResponse =>
      status == MatchmakerInterestPhotoExchangeStatus.pending &&
      !hasServerExpired(expiresAt);

  @override
  List<Object?> get props => [status, expiresAt, remainingSeconds];
}
