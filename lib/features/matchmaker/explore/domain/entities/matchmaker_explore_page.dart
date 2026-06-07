import 'package:equatable/equatable.dart';

import 'matchmaker_explore_user.dart';

/// One page of explore results. `hasMore` is derived from the 1-indexed page
/// position against the total page count — same convention as the users /
/// cases / conversations pages.
class MatchmakerExplorePage extends Equatable {
  final List<MatchmakerExploreUser> items;
  final int pageNumber;
  final int totalPages;

  const MatchmakerExplorePage({
    required this.items,
    required this.pageNumber,
    required this.totalPages,
  });

  bool get hasMore => pageNumber < totalPages;

  @override
  List<Object?> get props => [items, pageNumber, totalPages];
}
