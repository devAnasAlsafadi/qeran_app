import 'package:equatable/equatable.dart';

import 'matchmaker_user_row.dart';

/// One page of a matchmaker user list. `hasMore` is derived from the
/// 1-indexed page position against the total page count.
class MatchmakerUsersPage extends Equatable {
  final List<MatchmakerUserRow> items;
  final int pageNumber;
  final int totalPages;

  const MatchmakerUsersPage({
    required this.items,
    required this.pageNumber,
    required this.totalPages,
  });

  bool get hasMore => pageNumber < totalPages;

  @override
  List<Object?> get props => [items, pageNumber, totalPages];
}
