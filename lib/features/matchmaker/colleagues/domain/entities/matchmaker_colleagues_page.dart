import 'package:equatable/equatable.dart';

import 'matchmaker_colleague.dart';

/// One page of the colleague directory. `hasMore` is derived from the
/// 1-indexed page position against the total page count. When the endpoint
/// returns a bare array (no paging envelope), the data layer collapses it to a
/// single page (`pageNumber == totalPages == 1`).
class MatchmakerColleaguesPage extends Equatable {
  final List<MatchmakerColleague> items;
  final int pageNumber;
  final int totalPages;

  const MatchmakerColleaguesPage({
    required this.items,
    required this.pageNumber,
    required this.totalPages,
  });

  bool get hasMore => pageNumber < totalPages;

  @override
  List<Object?> get props => [items, pageNumber, totalPages];
}
