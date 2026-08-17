/// Drops filter questions no renderer can honestly display, and reports why.
///
/// Was duplicated as `DiscoveryFilterCubit._filterOutUnusable` and
/// `MatchmakerExploreFilterCubit._usableQuestions` — two copies that had already
/// drifted: the matchmaker dropped an unrenderable `unknown` question SILENTLY
/// while the user app logged it, so a dashboard misconfiguration was invisible
/// on exactly the side that configures the dashboard. Shared here so the drop
/// rules and the warnings are the same by construction rather than by
/// convention.
library;

import 'package:qeran/core/app_logger.dart';

import 'entities/discovery_filter_question.dart';
import 'entities/filter_question_type.dart';

/// [kept] is what the sheet renders. The two id lists name what was dropped and
/// why — returned as well as logged because `AppLogger` writes to
/// `dart:developer` and cannot be read back from a test (same reasoning as
/// `nonSearchableLongLists`).
typedef FilterScreening = ({
  List<DiscoveryFilterQuestion> kept,
  List<int> unknownWithoutOptions,
  List<int> rangeTypeWithoutFlag,
});

/// Keeps every `isRange` question (checked FIRST, so the dashboard can turn any
/// type into a slider) plus select / radio / checkbox / interests / text.
///
/// Two shapes are dropped:
///
/// * `unknown` with no options — an unrecognised wire type is renderable as a
///   choice list when it carries choices, and as nothing at all otherwise.
/// * `date` / `height` / `weight` without `isRange` — these are ranges by
///   contract and there is no single-value control to fall back to.
FilterScreening screenFilterQuestions({
  required List<DiscoveryFilterQuestion> all,
  required String logTag,
}) {
  final kept = <DiscoveryFilterQuestion>[];
  final unknownWithoutOptions = <int>[];
  final rangeTypeWithoutFlag = <int>[];

  for (final q in all) {
    if (q.isRange) {
      kept.add(q);
      continue;
    }
    switch (q.type) {
      case FilterQuestionType.select:
      case FilterQuestionType.radio:
      case FilterQuestionType.checkbox:
      case FilterQuestionType.interests:
      case FilterQuestionType.text:
        kept.add(q);
      case FilterQuestionType.unknown:
        if (q.options?.isNotEmpty ?? false) {
          kept.add(q);
        } else {
          unknownWithoutOptions.add(q.id);
          AppLogger.warning(
            'drop filter id=${q.id} — type "${q.type.name}" (the wire value is '
            'not one this build recognises) arrived with '
            '${q.options == null ? 'no options field' : 'an empty options list'}'
            '; an unrecognised type is only renderable as a choice list, so '
            'there is nothing to draw',
            tag: logTag,
          );
        }
      case FilterQuestionType.date:
      case FilterQuestionType.height:
      case FilterQuestionType.weight:
        rangeTypeWithoutFlag.add(q.id);
        AppLogger.warning(
          'drop filter id=${q.id} — ${q.type.name} requires isRange=true, got '
          'false (absent or explicit: the wire model defaults a missing flag to '
          'false, so the two cannot be told apart here); this type has no '
          'single-value control to fall back to',
          tag: logTag,
        );
    }
  }

  return (
    kept: kept,
    unknownWithoutOptions: unknownWithoutOptions,
    rangeTypeWithoutFlag: rangeTypeWithoutFlag,
  );
}
