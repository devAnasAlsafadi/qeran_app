import 'package:equatable/equatable.dart';

import 'case_stage.dart';
import 'compatibility_case.dart';

/// CLIENT-SIDE filter over the compatibility-cases list.
///
/// ⚠️ The `/matchmaker/compatibility-cases` endpoint accepts ONLY
/// `page`/`pageSize` — there is no server-side `status`/`search`. So this
/// filters only the cases ALREADY LOADED into the list. The list cubit raises
/// its pageSize toward the 100 max (cases are few per matchmaker) so "loaded"
/// is effectively the full set in practice; beyond that, scrolling to load
/// more pages widens what the filter can see.
///
/// The filter is by a single canonical [CaseStage] (null = "الكل", no stage
/// constraint) plus an optional name substring — the stage is matched via the
/// shared [caseStageOf] projection, so it lines up exactly with the detail
/// timeline (08 ≡ 06).
class MatchmakerCasesFilter extends Equatable {
  /// Selected canonical stage, or null for "الكل" (no stage constraint).
  final CaseStage? stage;

  /// Case-insensitive substring matched against either participant's first
  /// name. Empty = no name constraint.
  final String nameQuery;

  const MatchmakerCasesFilter({
    this.stage,
    this.nameQuery = '',
  });

  /// True when at least one constraint is set (drives the active-filter dot).
  bool get isActive => stage != null || nameQuery.trim().isNotEmpty;

  /// Applies the filter to [items]. A case passes when BOTH hold:
  ///   • name: query empty OR either participant's first name contains it;
  ///   • stage: none selected OR the case's current canonical stage equals it.
  List<CompatibilityCase> apply(List<CompatibilityCase> items) {
    if (!isActive) return items;
    final q = nameQuery.trim().toLowerCase();
    final selected = stage;
    return items.where((c) {
      final nameOk = q.isEmpty ||
          c.myUser.firstName.toLowerCase().contains(q) ||
          c.otherUser.firstName.toLowerCase().contains(q);
      final stageOk = selected == null || caseStageOf(c) == selected;
      return nameOk && stageOk;
    }).toList(growable: false);
  }

  MatchmakerCasesFilter copyWith({
    CaseStage? stage,
    bool clearStage = false,
    String? nameQuery,
  }) {
    return MatchmakerCasesFilter(
      stage: clearStage ? null : (stage ?? this.stage),
      nameQuery: nameQuery ?? this.nameQuery,
    );
  }

  @override
  List<Object?> get props => [stage, nameQuery];
}
