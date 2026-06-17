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
/// RangeFrom[<id>]       = "<min>"            (numeric range — age/height/weight)
/// RangeTo[<id>]         = "<max>"
/// ```
///
/// Empty/blank values are dropped, so a no-op filter yields a map carrying only
/// `page`/`pageSize` once merged by the datasource. The range maps are already
/// trimmed by the filter cubit (an edge is present only when the user moved it
/// off the question's min/max), so a one-sided range sends just one edge.
Map<String, String> buildExploreQuery({
  String? search,
  Gender? gender,
  Map<int, List<String>> questionFilters = const {},
  Map<int, double> rangeFrom = const {},
  Map<int, double> rangeTo = const {},
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
  rangeFrom.forEach((id, v) => query['RangeFrom[$id]'] = _num(v));
  rangeTo.forEach((id, v) => query['RangeTo[$id]'] = _num(v));
  return query;
}

/// Whole numbers send without a trailing `.0` (the server reads them as ints
/// for age/height/weight); fractional values keep their decimals.
String _num(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';
