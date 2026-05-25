import 'package:equatable/equatable.dart';

import 'like_profile_image.dart';
import 'like_request_status.dart';

/// One row in the Likes / Interests list. Maps 1:1 to the server's
/// `LikeRequestCardDto`. Same DTO is used for incoming and outgoing —
/// the surrounding [LikeRequestsData] carries the subscription gating.
///
/// **Locked cards** — when [isLocked] is true the server has redacted
/// the identity fields (`profileId == ""`, `name == ""`,
/// `profileImage == null`). The UI must NOT show the placeholder
/// strings; it shows the subscription-paywall variant of the card
/// instead. See `LikeUserCard._Locked` on the presentation side.
class LikeRequestCard extends Equatable {
  /// Server-side identifier for the like row. Used by future
  /// accept / reject endpoints — keep as int to match the wire type.
  final int likeRequestId;

  /// Other user's profile id. `""` when the row is locked.
  final String profileId;

  /// Other user's display name. `""` when the row is locked.
  final String name;

  final LikeProfileImage? profileImage;

  final LikeRequestStatus status;

  /// When the like was sent. `null` when the server omits it (the
  /// archived shape in the docs leaves it open).
  final DateTime? createdAt;

  /// Seconds until the pending like expires. `null` for any non-pending
  /// status (the wire type is `int | null`).
  final int? remainingSeconds;

  /// Allowed mutations for this row. Subscribed incoming pending rows
  /// receive `["accept", "reject"]`; outgoing and locked rows receive
  /// `[]`. The UI gates accept/reject buttons on this list, not on the
  /// tab — that way a server-side downgrade (e.g. subscription
  /// cancellation) hides the buttons automatically on the next refresh.
  final List<String> actions;

  /// Identity redacted by the server because the current user isn't
  /// subscribed. Always `false` on outgoing.
  final bool isLocked;

  const LikeRequestCard({
    required this.likeRequestId,
    required this.profileId,
    required this.name,
    required this.profileImage,
    required this.status,
    required this.createdAt,
    required this.remainingSeconds,
    required this.actions,
    required this.isLocked,
  });

  bool get canAccept => actions.contains('accept');
  bool get canReject => actions.contains('reject');

  @override
  List<Object?> get props => [
        likeRequestId,
        profileId,
        name,
        profileImage,
        status,
        createdAt,
        remainingSeconds,
        actions,
        isLocked,
      ];
}
