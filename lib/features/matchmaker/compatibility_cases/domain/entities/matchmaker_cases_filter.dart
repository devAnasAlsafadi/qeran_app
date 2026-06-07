import 'package:equatable/equatable.dart';

import 'compatibility_case.dart';
import 'formal_request_status.dart';

/// CLIENT-SIDE filter over the compatibility-cases list.
///
/// ⚠️ The `/matchmaker/compatibility-cases` endpoint accepts ONLY
/// `page`/`pageSize` — there is no server-side `status`/`search`. So this
/// filters only the cases ALREADY LOADED into the list. The list cubit raises
/// its pageSize toward the 100 max (cases are few per matchmaker) so "loaded"
/// is effectively the full set in practice; beyond that, scrolling to load
/// more pages widens what the filter can see.
class MatchmakerCasesFilter extends Equatable {
  /// Selected formal-request statuses. Empty = no status constraint.
  final Set<FormalRequestStatus> statuses;

  /// Case-insensitive substring matched against either participant's first
  /// name. Empty = no name constraint.
  final String nameQuery;

  const MatchmakerCasesFilter({
    this.statuses = const {},
    this.nameQuery = '',
  });

  /// True when at least one constraint is set (drives the active-filter dot).
  bool get isActive => statuses.isNotEmpty || nameQuery.trim().isNotEmpty;

  /// Applies the filter to [items]. A case passes when BOTH hold:
  ///   • name: query empty OR either participant's first name contains it;
  ///   • status: set empty OR the case has a formalRequest whose status is in
  ///     the set (cases with no formal request are excluded once a status is
  ///     selected — they have no status to match).
  List<CompatibilityCase> apply(List<CompatibilityCase> items) {
    if (!isActive) return items;
    final q = nameQuery.trim().toLowerCase();
    return items.where((c) {
      final nameOk = q.isEmpty ||
          c.myUser.firstName.toLowerCase().contains(q) ||
          c.otherUser.firstName.toLowerCase().contains(q);
      final status = c.formalRequest?.status;
      final statusOk = statuses.isEmpty ||
          (status != null && statuses.contains(status));
      return nameOk && statusOk;
    }).toList(growable: false);
  }

  MatchmakerCasesFilter copyWith({
    Set<FormalRequestStatus>? statuses,
    String? nameQuery,
  }) {
    return MatchmakerCasesFilter(
      statuses: statuses ?? this.statuses,
      nameQuery: nameQuery ?? this.nameQuery,
    );
  }

  @override
  List<Object?> get props => [statuses, nameQuery];
}
