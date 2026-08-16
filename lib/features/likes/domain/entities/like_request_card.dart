import 'package:equatable/equatable.dart';

import '../../../../core/utils/server_clock.dart';
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

  /// Optional compact facts displayed below the name when supplied by the
  /// server. Kept nullable for backward compatibility with older payloads.
  final int? age;
  final String? residence;
  final String? job;

  final LikeRequestStatus status;

  /// When the like was sent. `null` when the server omits it (the
  /// archived shape in the docs leaves it open).
  final DateTime? createdAt;

  /// Seconds until the pending like expires. `null` for any non-pending
  /// status (the wire type is `int | null`).
  final int? remainingSeconds;

  /// Stable server expiry for the pending request. The UI builds its live
  /// countdown from this timestamp and uses [remainingSeconds] once, when the
  /// response arrives, to calibrate away any device-clock skew.
  final DateTime? expiresAt;

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
    this.age,
    this.residence,
    this.job,
    required this.status,
    required this.createdAt,
    required this.remainingSeconds,
    this.expiresAt,
    required this.actions,
    required this.isLocked,
  });

  bool get canAccept => actions.contains('accept');
  bool get canReject => actions.contains('reject');

  /// Still genuinely open — the ONE question the UI should ask before showing
  /// a live countdown or accept/reject controls.
  ///
  /// `status == pending` alone is not enough any more. The backend used to
  /// null [expiresAt] once a request lapsed, so "pending with a deadline"
  /// implied "still running"; it now returns the real timestamp whatever the
  /// outcome, and a lapsed row keeps its Pending status until the server
  /// sweeps it. Presence of the field therefore proves nothing — only the
  /// comparison does.
  bool get isAwaitingResponse =>
      status == LikeRequestStatus.pending && !hasServerExpired(expiresAt);

  @override
  List<Object?> get props => [
    likeRequestId,
    profileId,
    name,
    profileImage,
    age,
    residence,
    job,
    status,
    createdAt,
    remainingSeconds,
    expiresAt,
    actions,
    isLocked,
  ];
}
