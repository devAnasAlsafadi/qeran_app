/// Lifecycle of a like request as reported by `/api/likes/incoming`
/// and `/api/likes/outgoing`.
///
/// The backend currently emits numeric statuses (`0..3`) on the wire,
/// but earlier documentation used the capitalised strings
/// (`"Pending" | "Accepted" | "Rejected" | "Expired"`). [likeRequestStatusFromWire]
/// accepts both shapes so a future server-side switch back to strings
/// (or a mixed deployment) doesn't break the client.
///
/// Unknown values map to [unknown] — UI treats it like an expired row
/// (no actions, neutral status chip) so an unexpected value from the
/// server can't crash the screen.
enum LikeRequestStatus {
  pending,
  accepted,
  rejected,
  expired,

  /// Defensive fallback when the server sends a value we don't
  /// recognise.
  unknown,
}

/// Accepts either an `int` (current backend) or a `String` (original
/// documented contract). Anything else falls back to [LikeRequestStatus.unknown].
LikeRequestStatus likeRequestStatusFromWire(Object? raw) {
  if (raw is int) {
    switch (raw) {
      case 0:
        return LikeRequestStatus.pending;
      case 1:
        return LikeRequestStatus.accepted;
      case 2:
        return LikeRequestStatus.rejected;
      case 3:
        return LikeRequestStatus.expired;
      default:
        return LikeRequestStatus.unknown;
    }
  }
  if (raw is String) {
    switch (raw.toLowerCase()) {
      case 'pending':
        return LikeRequestStatus.pending;
      case 'accepted':
        return LikeRequestStatus.accepted;
      case 'rejected':
        return LikeRequestStatus.rejected;
      case 'expired':
        return LikeRequestStatus.expired;
      default:
        return LikeRequestStatus.unknown;
    }
  }
  // Some servers serialise enums as `num` (`0.0` etc.) — coerce.
  if (raw is num) {
    return likeRequestStatusFromWire(raw.toInt());
  }
  return LikeRequestStatus.unknown;
}
