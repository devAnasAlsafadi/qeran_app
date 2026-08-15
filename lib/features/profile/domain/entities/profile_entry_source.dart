/// Where the user opened the Full Profile Details screen from.
///
/// Drives which affordances appear:
/// * like/pass action bar         → only for `chat` (see [canReactFromEntry])
/// * share-with-matchmaker button → discovery, likes, matches
/// * edit-answers button          → only for `mine`
///
/// Keep entries lower-camelCase to match the Dart enum style; no
/// stringly-typed comparisons elsewhere in the code base.
enum ProfileEntrySource { discovery, chat, likes, matches, settings, mine }

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

/// Whether the viewer may like or pass the profile opened from [entry].
///
/// BOTH inputs are load-bearing, which is why entry alone is not the gate:
///
/// * The bar belongs to one entry — a profile the matchmaker shared into a
///   chat, which the member then acts on. It deliberately replaces the
///   share CTA there (`showShareForEntry` is false for `chat`).
/// * It belongs to one role. The matchmaker reuses that very chat screen, so
///   an entry-only gate handed her like/pass on a profile she is merely
///   reviewing — and the cubit behind those buttons posts to /likes and
///   /discovery/skip on HER account.
///
/// Policy lives here, beside [isPeerProfileEntry], rather than on the profile
/// entity: `OtherProfile` is what the server returned about someone else, and
/// who is looking is not part of that.
bool canReactFromEntry(
  ProfileEntrySource entry, {
  required bool isMatchmaker,
}) => entry == ProfileEntrySource.chat && !isMatchmaker;
