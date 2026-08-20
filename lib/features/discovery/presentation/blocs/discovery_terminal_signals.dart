part of 'discovery_state.dart';

/// Why the deck has nothing left to show, and therefore which remedy the empty
/// view offers.
///
/// Kept apart from the state's data fields because these are the arc's actual
/// subject: two INDEPENDENT signals, one the server can report and one only the
/// client can observe. Reading them side by side is what makes it obvious they
/// are not alternatives — both can be true at once, and each drives its own
/// call to action.
extension DiscoveryTerminalSignals on DiscoveryLoaded {
  /// The user was handed profiles and swiped past the last one, with no page
  /// left to fetch. The server cannot report this — it never hears about the
  /// swipes — so the client watches for it instead.
  ///
  /// `profiles.isNotEmpty` is LOAD-BEARING, not a tidiness check: [isExhausted]
  /// is `currentIndex >= profiles.length`, which is also true of a deck that
  /// never had anything (`0 >= 0`). Drop the guard and "you have seen everyone"
  /// fires at a user who was shown nobody.
  bool get sawEveryLoadedProfile =>
      profiles.isNotEmpty && isExhausted && !hasMore;

  /// Union of the two independent signals, per the agreed CTA rule: the server
  /// saying so, OR the client having watched it happen. Either one alone is
  /// enough to offer "start over".
  bool get hasSeenEveryone =>
      currentReason == DiscoveryEmptyReason.seenAll || sawEveryLoadedProfile;

  /// Server-only signal: the query matched nobody, so the seen ledger is
  /// irrelevant and the filters are the remedy. Deliberately NOT unioned with
  /// [hasSeenEveryone] — both can be true at once, and each drives its own CTA.
  bool get filtersMatchedNobody =>
      currentReason == DiscoveryEmptyReason.noMatchesForFilters;
}
