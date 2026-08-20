/// Why the deck has nothing left to show, as reported by the backend.
///
/// Sent on the paged payload as `data.reason`. Two things make it nullable
/// everywhere and never load-bearing:
///
/// * a page that CARRIES profiles has no reason to report, and
/// * a backend predating the field sends nothing at all.
///
/// So `null` is the normal case, not an error, and every consumer must degrade
/// to the generic empty state rather than assume a reason is present.
///
/// It also cannot describe the case where the server returned profiles and the
/// user swiped through all of them — the server never learns that happened.
/// That one is the client's own to detect.
enum DiscoveryEmptyReason {
  /// Every profile matching the query has already been seen. The remedy is to
  /// clear the seen ledger, not to widen the query.
  seenAll,

  /// The active filters matched nobody. The remedy is the filters; the seen
  /// ledger is irrelevant because nothing matched in the first place.
  noMatchesForFilters,

  /// The backend named a reason this build does not know.
  ///
  /// Deliberately distinct from `null`: both render the generic empty state,
  /// but this one means "the server said something we could not use" — worth
  /// telling apart when a new reason ships and an old client is still in the
  /// wild.
  unknown;

  /// Parses the wire value, tolerating everything a server might actually send.
  ///
  /// `null`, a non-string, and blank all mean "no reason given" → `null`. An
  /// unrecognised name maps to [unknown] rather than throwing: a new reason
  /// added server-side must never break a shipped client's empty state.
  /// Matched case-insensitively so casing drift cannot silently downgrade a
  /// reason we do support.
  static DiscoveryEmptyReason? fromWire(Object? raw) {
    if (raw == null) return null;
    final value = raw.toString().trim();
    if (value.isEmpty) return null;
    return switch (value.toUpperCase()) {
      'SEEN_ALL' => seenAll,
      'NO_MATCHES_FOR_FILTERS' => noMatchesForFilters,
      _ => unknown,
    };
  }
}
