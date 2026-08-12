/// Where the user opened the Full Profile Details screen from.
///
/// Drives which affordances appear:
/// * pass/like floating actions   → only for `discovery`
/// * share-with-matchmaker button → discovery, likes, matches
/// * edit-answers button          → only for `mine`
///
/// Keep entries lower-camelCase to match the Dart enum style; no
/// stringly-typed comparisons elsewhere in the code base.
enum ProfileEntrySource {
  discovery,
  chat,
  likes,
  matches,
  settings,
  mine,
}

/// Whether this entry shows ANOTHER member's profile.
///
/// Peer surfaces render photos blurred unconditionally — the profile screen is
/// not a reveal surface. Clear photos live in exactly one place, the
/// compatibility tab's one-time viewing window, so the exchange status does
/// not vary what the profile shows.
bool isPeerProfileEntry(ProfileEntrySource entry) => switch (entry) {
  ProfileEntrySource.discovery ||
  ProfileEntrySource.chat ||
  ProfileEntrySource.likes ||
  ProfileEntrySource.matches => true,
  ProfileEntrySource.settings || ProfileEntrySource.mine => false,
};
