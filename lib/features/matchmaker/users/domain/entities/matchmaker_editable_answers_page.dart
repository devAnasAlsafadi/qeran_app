import 'package:equatable/equatable.dart';

import 'matchmaker_editable_answer.dart';

/// One page of editable answers (the standard PagedResult envelope:
/// `{data[], pageNumber, pageSize, totalCount, totalPages}`).
class MatchmakerEditableAnswersPage extends Equatable {
  final List<MatchmakerEditableAnswer> items;
  final int pageNumber;
  final int totalPages;

  const MatchmakerEditableAnswersPage({
    required this.items,
    required this.pageNumber,
    required this.totalPages,
  });

  bool get hasMore => pageNumber < totalPages;

  @override
  List<Object?> get props => [items, pageNumber, totalPages];
}
