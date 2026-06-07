import 'package:qeran/core/enum/gender.dart';

/// Builds the explore query map from the active selections.
///
/// PORTS `DiscoveryFilterCubit.buildPayload()`'s confirmed scheme — exactly
/// mirrored here so the explore feature does NOT depend on discovery's cubit:
///
/// ```
/// search               = "<text>"
/// gender               = "Male" | "Female"
/// QuestionFilters[<id>] = "<v1>,<v2>,<v3>"   (comma-joined OR for multi)
/// ```
///
/// Empty/blank values are dropped, so a no-op filter yields a map carrying only
/// `page`/`pageSize` once merged by the datasource. (Range filters —
/// `RangeFrom[id]`/`RangeTo[id]` — are not part of this signature; the explore
/// doc's filter example uses only `QuestionFilters`/`search`/`gender`. If S4b's
/// sheet surfaces ranges, extend here mirroring buildPayload's range branch.)
Map<String, String> buildExploreQuery({
  String? search,
  Gender? gender,
  Map<int, List<String>> questionFilters = const {},
}) {
  final query = <String, String>{};
  final trimmedSearch = search?.trim();
  if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
    query['search'] = trimmedSearch;
  }
  if (gender != null) {
    query['gender'] = gender.apiValue;
  }
  questionFilters.forEach((id, values) {
    final nonEmpty = values.where((v) => v.isNotEmpty).toList();
    if (nonEmpty.isNotEmpty) {
      query['QuestionFilters[$id]'] = nonEmpty.join(',');
    }
  });
  return query;
}
