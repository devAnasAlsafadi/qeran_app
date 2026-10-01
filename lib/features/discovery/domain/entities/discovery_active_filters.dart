import 'discovery_filter_selection.dart';

/// The filters narrowing the Discovery deck: the [query] sent with every page
/// fetch, and the filter sheet's [selections] behind it.
///
/// One value, so the two are always replaced together. The [query] is what
/// the server sees; the [selections] never affect it — they are kept only to
/// re-seed the sheet when it reopens, because the flat query is lossy (it
/// can't be rendered back into chips or sliders).
class DiscoveryActiveFilters {
  /// A null or empty [query] means nothing narrows the deck.
  DiscoveryActiveFilters({
    Map<String, String>? query,
    Map<int, DiscoveryFilterSelection> selections = const {},
  }) : query = (query == null || query.isEmpty)
           ? null
           : Map.unmodifiable(query),
       selections = Map.unmodifiable(selections);

  const DiscoveryActiveFilters._none() : query = null, selections = const {};

  /// Nothing narrows the deck.
  static const none = DiscoveryActiveFilters._none();

  /// The flat query map threaded into every page fetch — page 1 and every
  /// prefetch — so pagination stays consistent with the filters. Null while
  /// the deck is unconstrained.
  final Map<String, String>? query;

  final Map<int, DiscoveryFilterSelection> selections;

  /// True while a filter is constraining the deck. Read off the [query], not
  /// the [selections], so it answers "is the server being narrowed?" rather
  /// than "does the sheet have chips ticked". Lets the empty state tell
  /// "nobody left" apart from "your filter matched nobody".
  bool get isActive => query != null;
}
