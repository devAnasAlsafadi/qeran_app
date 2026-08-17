/// Pure selection rules shared by BOTH filter sheets (user discovery + the
/// matchmaker explore sheet). The two cubits are deliberately parallel rather
/// than shared, but these rules must be byte-identical across the apps, so they
/// live here as free functions instead of being duplicated twice.
library;

import 'package:qeran/core/app_logger.dart';

import 'entities/discovery_filter_question.dart';
import 'entities/discovery_filter_selection.dart';
import 'entities/filter_question_type.dart';

/// Reconciles a seeded selection map with the questions as the server now
/// describes them (E4).
///
/// The dashboard can turn `isMultiSelect` off on a question a user already
/// applied several values to. Reopening the sheet would otherwise show three
/// selected chips on a facet that accepts one. Only an EXPLICIT `false`
/// collapses — a null flag means "client keeps inferring", which is multi.
///
/// Every non-empty [MultiValueSelection] collapses, not just the >1 case: a
/// one-value multi renders identically to a single but makes the next tap
/// SET instead of TOGGLE OFF (`setSingleValue` compares against
/// [SingleValueSelection] only), so the chip the user taps to clear would stay
/// lit. An empty multi is dropped outright.
Map<int, DiscoveryFilterSelection> collapseForbiddenMultiSelections({
  required List<DiscoveryFilterQuestion> questions,
  required Map<int, DiscoveryFilterSelection> seeded,
  required String logTag,
}) {
  if (seeded.isEmpty) return <int, DiscoveryFilterSelection>{};
  final out = Map<int, DiscoveryFilterSelection>.from(seeded);
  final byId = {for (final q in questions) q.id: q};

  for (final entry in seeded.entries) {
    final question = byId[entry.key];
    if (question == null || !question.forbidsMultiSelect) continue;
    final selection = entry.value;
    if (selection is! MultiValueSelection) continue;

    if (selection.values.isEmpty) {
      out.remove(entry.key);
      continue;
    }
    out[entry.key] = SingleValueSelection(selection.values.first);
    if (selection.values.length > 1) {
      AppLogger.warning(
        'filter id=${entry.key} — isMultiSelect=false, collapsed '
        '${selection.values.length} seeded values to '
        '"${selection.values.first}"',
        tag: logTag,
      );
    }
  }
  return out;
}

/// The questions whose `isSearchable: false` overrides a list long enough that
/// the client would have given it a search box.
///
/// Purely for OUR visibility — the dashboard still wins, nothing is changed or
/// dropped. Call it once per load (both cubits do) so the log carries one line
/// per offending question rather than one per rebuild.
///
/// Returns the ids as well as logging them because `AppLogger` writes to
/// `dart:developer` and cannot be intercepted from a test; the return value is
/// what lets "one warning per offending question, and none for the rest" be
/// asserted instead of eyeballed.
List<int> nonSearchableLongLists({
  required List<DiscoveryFilterQuestion> questions,
  required int optionCountThreshold,
  required String logTag,
}) {
  final ids = <int>[];
  for (final q in questions) {
    if (!q.exceedsSearchThresholdWithoutSearch(
      optionCountThreshold: optionCountThreshold,
    )) {
      continue;
    }
    ids.add(q.id);
    AppLogger.warning(
      'filter id=${q.id} — isSearchable=false with ${q.options!.length} '
      'options (threshold $optionCountThreshold); rendering chips as the '
      'dashboard asked',
      tag: logTag,
    );
  }
  return ids;
}

/// Which edges of a [RangeSelection] actually go on the wire.
///
/// The backend treats a present `RangeFrom` / `RangeTo` as a constraint, so
/// echoing the question's own advertised bounds back at it narrows nothing while
/// still excluding every profile whose value is missing on that field. An edge
/// is therefore emitted ONLY when the user moved it off the bound:
///
/// * full range (both thumbs untouched) → `(null, null)`, send nothing
/// * one-sided                          → just that edge
///
/// "Untouched" is structural, not tracked: opening the sheet seeds the thumbs AT
/// the bounds, so a seeded-but-unmoved range compares equal and trims away. A
/// user who deliberately drags a thumb back to the bound gets the same result,
/// which is correct — the constraint they expressed is "no constraint".
///
/// Two shapes are refused outright rather than trimmed, because both mean the
/// selection and the question disagree:
///
/// * a range on a question that does not advertise one (`isRange == false`) —
///   `effectiveMin`/`effectiveMax` would be type defaults invented by the
///   client, so trimming against them is meaningless
/// * `min > max` — structurally impossible through the slider; asserts in debug
///   so a future bug fails loudly in tests, warns and skips in release rather
///   than sending an empty-by-construction filter
({int? from, int? to}) trimmedRangeEdges({
  required DiscoveryFilterQuestion question,
  required RangeSelection selection,
  required String logTag,
}) {
  const skip = (from: null, to: null);

  if (!question.isRange) {
    AppLogger.warning(
      'filter id=${question.id} — range selection on a non-range '
      '${question.type.name} question, skipped',
      tag: logTag,
    );
    return skip;
  }

  assert(
    selection.min <= selection.max,
    'range filter id=${question.id} has min > max '
    '(${selection.min} > ${selection.max}) — the slider cannot produce this',
  );
  if (selection.min > selection.max) {
    AppLogger.warning(
      'filter id=${question.id} — inverted range '
      '${selection.min}..${selection.max}, skipped',
      tag: logTag,
    );
    return skip;
  }

  return (
    from: selection.min > question.effectiveMin ? selection.min : null,
    to: selection.max < question.effectiveMax ? selection.max : null,
  );
}

/// Debug breadcrumb for the combination Tariq flagged: a `radio` / `select`
/// question sending SEVERAL values.
///
/// No wire change is involved — `QuestionFilters[id]` has always accepted
/// `v1,v2,v3`, and the server splits on the comma regardless of the question's
/// type. This logs when the combination actually goes out so that if the
/// contract ever narrows, the request that broke is already in the log rather
/// than something to reproduce.
void logMultiValueOnSingleChoiceType({
  required DiscoveryFilterQuestion question,
  required List<String> values,
  required String logTag,
}) {
  if (values.length < 2) return;
  if (question.type != FilterQuestionType.radio &&
      question.type != FilterQuestionType.select) {
    return;
  }
  final source = question.isMultiSelect == null ? 'inferred' : 'dashboard';
  AppLogger.debug(
    'filter id=${question.id} — ${question.type.name} sending '
    '${values.length} values as comma-joined QuestionFilters '
    '($source multi-select): ${values.join(',')}',
    tag: logTag,
  );
}
