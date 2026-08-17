/// Serializers that turn a filter sheet's selections into request parameters.
/// Split from `filter_selection_rules.dart` (which holds the RULES the two apps
/// must agree on) so neither file outgrows the 200-line limit; both are shared
/// by the user discovery sheet and the matchmaker explore sheet.
library;

import 'entities/discovery_filter_question.dart';
import 'entities/discovery_filter_selection.dart';
import 'filter_selection_rules.dart';

/// The user app's flat query map, keyed to the backend's confirmed contract:
///
/// ```
/// RangeFrom[<id>] = "<min>"
/// RangeTo[<id>]   = "<max>"
/// QuestionFilters[<id>] = "<value>"
/// QuestionFilters[<id>] = "<v1>,<v2>,<v3>"
/// ```
///
/// Range edges are trimmed per [trimmedRangeEdges], so a full-range selection
/// contributes no keys at all. Empty selections produce an empty map — the
/// caller treats that as "clear all filters" and calls
/// `DiscoveryCubit.applyFilters(null)`.
Map<String, String> buildDiscoveryFilterPayload({
  required List<DiscoveryFilterQuestion> questions,
  required Map<int, DiscoveryFilterSelection> selections,
  required String logTag,
}) {
  final payload = <String, String>{};
  final byId = {for (final q in questions) q.id: q};
  selections.forEach((id, selection) {
    switch (selection) {
      case RangeSelection():
        final question = byId[id];
        if (question == null) return;
        final edges = trimmedRangeEdges(
          question: question,
          selection: selection,
          logTag: logTag,
        );
        if (edges.from != null) payload['RangeFrom[$id]'] = '${edges.from}';
        if (edges.to != null) payload['RangeTo[$id]'] = '${edges.to}';
      case SingleValueSelection(value: final v):
        if (v.isNotEmpty) payload['QuestionFilters[$id]'] = v;
      case MultiValueSelection(values: final vs):
        if (vs.isEmpty) return;
        payload['QuestionFilters[$id]'] = vs.join(',');
        _auditMultiValue(byId[id], vs, logTag);
    }
  });
  return payload;
}

/// The matchmaker explore sheet's `{questionId: [values]}` shape, which its
/// datasource turns into the same comma-joined `QuestionFilters[id]`. Pure and
/// question-free so the explore screen can convert a returned selection map
/// without holding a cubit. RANGE selections are intentionally ignored — the
/// explore request carries ranges in separate maps.
Map<int, List<String>> exploreQuestionFiltersFromSelections(
  Map<int, DiscoveryFilterSelection> selections,
) {
  final out = <int, List<String>>{};
  selections.forEach((id, selection) {
    switch (selection) {
      case SingleValueSelection(value: final v):
        if (v.isNotEmpty) out[id] = [v];
      case MultiValueSelection(values: final vs):
        final nonEmpty = vs.where((v) => v.isNotEmpty).toList();
        if (nonEmpty.isNotEmpty) out[id] = nonEmpty;
      case RangeSelection():
        break; // carried separately by the explore request
    }
  });
  return out;
}

/// [exploreQuestionFiltersFromSelections] plus the wire audit, for the cubit —
/// which, unlike the screen, has the question list to audit against.
Map<int, List<String>> exploreQuestionFilters({
  required List<DiscoveryFilterQuestion> questions,
  required Map<int, DiscoveryFilterSelection> selections,
  required String logTag,
}) {
  final filters = exploreQuestionFiltersFromSelections(selections);
  final byId = {for (final q in questions) q.id: q};
  filters.forEach((id, values) => _auditMultiValue(byId[id], values, logTag));
  return filters;
}

void _auditMultiValue(
  DiscoveryFilterQuestion? question,
  List<String> values,
  String logTag,
) {
  if (question == null) return;
  logMultiValueOnSingleChoiceType(
    question: question,
    values: values,
    logTag: logTag,
  );
}
