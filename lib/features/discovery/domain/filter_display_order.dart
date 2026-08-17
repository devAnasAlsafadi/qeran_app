/// Dashboard-controlled ordering for filter questions and their options (E1/E2).
///
/// Kept out of `filter_selection_rules.dart` on both counts: that file is about
/// what a SELECTION means, this is about what order things are DRAWN in, and
/// folding them together would push it past the 200-line limit.
///
/// Both filter cubits call [sortedFilterQuestions] once, on load. Sorting in
/// `build` would redo this work on every rebuild — including every keystroke in
/// a searchable facet — for a result that cannot change until the next fetch.
library;

import 'entities/discovery_filter_option.dart';
import 'entities/discovery_filter_question.dart';

/// Questions ordered by `displayPriority`, each with its own options ordered the
/// same way.
///
/// Ascending, with absent priorities last ([kUnprioritizedOrderKey]) and ties
/// broken by original position — so a payload where the dashboard prioritized
/// nothing comes back in exactly the order the server sent it.
///
/// Returns new lists and never mutates the input: `List.sort` sorts in place,
/// and these lists come from the datasource, which is free to hand out
/// unmodifiable ones.
List<DiscoveryFilterQuestion> sortedFilterQuestions(
  List<DiscoveryFilterQuestion> questions,
) {
  final withSortedOptions = questions.map((q) {
    final options = q.options;
    // Nothing to reorder, and copyWith would allocate for no reason.
    if (options == null || options.length < 2) return q;
    return q.copyWith(
      options: _stableSortBy(options, (o) => o.effectiveOrderKey),
    );
  }).toList(growable: false);

  return _stableSortBy(withSortedOptions, (q) => q.effectiveOrderKey);
}

/// `List.sort` is NOT guaranteed stable in Dart, so equal keys can be reordered
/// arbitrarily — and "arbitrarily" includes differently between runs on the same
/// input. Decorating with the original index makes the comparison total, which
/// is what actually delivers E1's tie-break rule.
List<T> _stableSortBy<T>(List<T> items, int Function(T item) key) {
  final decorated = List.generate(
    items.length,
    (i) => (index: i, value: items[i]),
    growable: false,
  );
  decorated.sort((a, b) {
    final byKey = key(a.value).compareTo(key(b.value));
    return byKey != 0 ? byKey : a.index.compareTo(b.index);
  });
  return decorated.map((d) => d.value).toList(growable: false);
}
