import 'package:flutter/material.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Which terminal state the deck landed in, and what it says.
///
/// The two inputs are INDEPENDENT — the server reporting that a query matched
/// nobody, and the client having watched the user swipe past the last card —
/// so all four combinations are reachable and each gets its own copy.
///
/// Split from the view because it is the decision, not the layout: what the
/// user is told is worth reading without scrolling past a widget tree, and it
/// can be asserted without pumping one.
enum DiscoveryEmptyBranch {
  /// Seen everyone, and the filters are not the problem.
  seenAll,

  /// The filters matched nobody. Says nothing about what the user has seen —
  /// a filter nobody matches means they were shown no one at all.
  filtered,

  /// Both at once: the filter matched nobody new, and everyone it did match is
  /// already seen. Two legitimate remedies, so the view offers both.
  both,

  /// Nothing known. Falls back to the long-standing generic copy rather than
  /// guessing at a cause.
  generic;

  static DiscoveryEmptyBranch resolve({
    required bool seenEveryone,
    required bool filtersMatchedNobody,
  }) {
    if (seenEveryone && filtersMatchedNobody) return both;
    if (filtersMatchedNobody) return filtered;
    if (seenEveryone) return seenAll;
    return generic;
  }

  IconData get icon => switch (this) {
    // Completion, not absence — the user did not hit a wall, they finished.
    seenAll => Icons.done_all_rounded,
    filtered || both => Icons.filter_alt_off_outlined,
    generic => Icons.people_outline_rounded,
  };

  String get titleKey => switch (this) {
    seenAll => LocaleKeys.discovery_empty_seen_all_title,
    // The filter is the more actionable of the two problems, so it leads.
    filtered || both => LocaleKeys.discovery_empty_filtered_title,
    generic => LocaleKeys.discovery_empty_title,
  };

  String get messageKey => switch (this) {
    seenAll => LocaleKeys.discovery_empty_seen_all_message,
    filtered => LocaleKeys.discovery_empty_filtered_subtitle,
    both => LocaleKeys.discovery_empty_filtered_seen_all_message,
    generic => LocaleKeys.discovery_empty_subtitle,
  };
}
