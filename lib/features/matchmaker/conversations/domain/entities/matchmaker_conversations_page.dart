import 'package:equatable/equatable.dart';

import 'matchmaker_conversation.dart';

/// One page of matchmaker conversations. `hasMore` is derived from the
/// 1-indexed page position against the total page count.
class MatchmakerConversationsPage extends Equatable {
  final List<MatchmakerConversation> items;
  final int pageNumber;
  final int totalPages;

  const MatchmakerConversationsPage({
    required this.items,
    required this.pageNumber,
    required this.totalPages,
  });

  bool get hasMore => pageNumber < totalPages;

  @override
  List<Object?> get props => [items, pageNumber, totalPages];
}
