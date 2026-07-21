/// Sealed result of a Like attempt. Semantic outcomes the server can
/// return on the `Right` side of `Either<Failure, LikeOutcome>` — they
/// are not transport failures and the cubit branches on them to decide
/// whether to advance, snap back, or show the paywall.
///
/// Transport-level problems (network, timeout, parse) stay on the
/// `Left` side as `Failure` and surface as a generic error toast.
sealed class LikeOutcome {
  const LikeOutcome();
}

/// Server recorded the like. `likeId` is the row id returned in `data`
/// (a string like `"42"`).
final class LikeAccepted extends LikeOutcome {
  final String likeId;
  const LikeAccepted({required this.likeId});
}

/// User has no active subscription OR their like quota is exhausted.
/// UI shows the burgundy paywall sheet; card stays in place.
final class LikePaywall extends LikeOutcome {
  final String serverMessage;
  const LikePaywall({required this.serverMessage});
}

/// A pending or accepted like already exists between the two users.
/// UI advances the card and shows a transient toast.
final class LikeAlreadyPending extends LikeOutcome {
  final String serverMessage;
  const LikeAlreadyPending({required this.serverMessage});
}

/// Server rejected the like because the two users share a gender. The
/// profile should never have reached the deck — UI advances defensively.
final class LikeGenderMismatch extends LikeOutcome {
  final String serverMessage;
  const LikeGenderMismatch({required this.serverMessage});
}

/// Target user was removed, hid their profile, or is otherwise no
/// longer visible to the current user.
final class LikeUserUnavailable extends LikeOutcome {
  final String serverMessage;
  const LikeUserUnavailable({required this.serverMessage});
}

/// Caller's profile is not yet approved (`PROFILE_NOT_APPROVED`). Sending a
/// like is gated until the matchmaker approves. UI keeps the card in place
/// (no advance) and shows a localized "under review" toast — NOT a paywall.
final class LikeUnderReview extends LikeOutcome {
  final String serverMessage;
  const LikeUnderReview({required this.serverMessage});
}
