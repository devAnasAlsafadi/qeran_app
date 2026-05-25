/// Lifecycle status of my own profile (returned by `GET /api/profile`
/// as `profileStatus`). Drives the status banner on the My Profile
/// screen.
enum ProfileStatus {
  /// Normal state — the profile shows in Discovery.
  visible,

  /// Backend is awaiting matchmaker review.
  pendingReview,

  /// User has hidden their profile from Discovery.
  hidden,

  /// Matchmaker rejected the profile.
  rejected,

  /// Unrecognised wire value — render no banner.
  unknown;

  static ProfileStatus fromString(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'visible':
        return ProfileStatus.visible;
      case 'pendingreview':
      case 'pending':
        return ProfileStatus.pendingReview;
      case 'hidden':
        return ProfileStatus.hidden;
      case 'rejected':
        return ProfileStatus.rejected;
      default:
        return ProfileStatus.unknown;
    }
  }
}
