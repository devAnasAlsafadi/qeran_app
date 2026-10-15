import 'package:qeran/core/enum/gender.dart';

/// Builds the `POST matchmaker/explore/search` body (`MatchmakerExploreFilter`)
/// from the active selections (run 11: the filters left the query string,
/// which every filter set pushed past IIS's 2,048 characters):
///
/// ```
/// page, pageSize
/// search          = "<text>"
/// gender          = "Male" | "Female"
/// questionFilters = { "<id>": "<v1>,<v2>,<v3>" }   (comma-joined OR for multi)
/// rangeFrom       = { "<id>": <min> }              (age/height/weight)
/// rangeTo         = { "<id>": <max> }
/// ```
///
/// Empty/blank values are dropped and empty maps left out, so a no-op filter
/// sends only `page` and `pageSize`. The range maps are already trimmed by the
/// filter cubit (an edge is present only when the user moved it off the
/// question's min/max), so a one-sided range sends just one edge.
Map<String, dynamic> buildExploreBody({
  required int page,
  required int pageSize,
  String? search,
  Gender? gender,
  Map<int, List<String>> questionFilters = const {},
  Map<int, double> rangeFrom = const {},
  Map<int, double> rangeTo = const {},
}) {
  final trimmedSearch = search?.trim();
  final questions = <String, String>{
    for (final MapEntry(:key, :value) in questionFilters.entries)
      if (value.where((v) => v.isNotEmpty).toList() case final nonEmpty
          when nonEmpty.isNotEmpty)
        '$key': nonEmpty.join(','),
  };
  return {
    'page': page,
    'pageSize': pageSize,
    if (trimmedSearch != null && trimmedSearch.isNotEmpty)
      'search': trimmedSearch,
    if (gender != null) 'gender': gender.apiValue,
    if (questions.isNotEmpty) 'questionFilters': questions,
    if (rangeFrom.isNotEmpty) 'rangeFrom': _edges(rangeFrom),
    if (rangeTo.isNotEmpty) 'rangeTo': _edges(rangeTo),
  };
}

/// Whole numbers send as integers (the server reads them as ints for
/// age/height/weight); fractional values keep their decimals.
Map<String, num> _edges(Map<int, double> edges) => {
  for (final MapEntry(:key, :value) in edges.entries)
    '$key': value == value.roundToDouble() ? value.toInt() : value,
};
