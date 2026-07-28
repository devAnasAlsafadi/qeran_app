/// State of the matchmaker's outstanding "please upload a photo" request for
/// one user (`imageRequestStatus` on the matchmaker's view of a profile).
///
/// Set to [pending] by `POST /api/matchmaker/users/{userId}/request-image` and
/// flipped to [approved] once the user uploads an image after that request.
/// It is the persisted answer to "have I already asked?", which the client
/// could not know before: a local flag would not survive a relaunch and would
/// then lie about whether a request is outstanding.
enum MatchmakerImageRequestStatus {
  /// Nothing outstanding — offer "طلب صورة".
  none,

  /// Asked; the user hasn't uploaded since — show the awaiting state, no
  /// second request.
  pending,

  /// The user uploaded after the request — nothing left to ask for.
  approved;

  /// Absent / unrecognised → [none], so a payload without the field (or from
  /// before the rollout) behaves exactly as it did before: offer the request.
  static MatchmakerImageRequestStatus fromString(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    return switch (normalized) {
      'pending' => MatchmakerImageRequestStatus.pending,
      'approved' => MatchmakerImageRequestStatus.approved,
      _ => MatchmakerImageRequestStatus.none,
    };
  }

  /// True only while a request is outstanding — the one state that replaces
  /// the request button with an awaiting label.
  bool get isAwaitingUpload => this == MatchmakerImageRequestStatus.pending;
}
