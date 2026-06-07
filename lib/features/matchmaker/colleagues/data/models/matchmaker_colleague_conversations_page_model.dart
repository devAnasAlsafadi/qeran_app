import '../../../conversations/domain/entities/matchmaker_conversations_page.dart';
import '../../../shared/data/json_parsers.dart';
import 'matchmaker_colleague_conversation_model.dart';

/// Wire model for the paginated `data` object returned by
/// `GET /api/matchmaker/conversations/colleagues` — the same
/// `{ data:[...rows], pageNumber, totalPages }` envelope as user
/// conversations. Rows arrive server-sorted by `lastMessageAt` DESC, so they
/// render as-is. Produces the generic [MatchmakerConversationsPage] entity.
class MatchmakerColleagueConversationsPageModel {
  final List<MatchmakerColleagueConversationModel> items;
  final int pageNumber;
  final int totalPages;

  const MatchmakerColleagueConversationsPageModel({
    required this.items,
    required this.pageNumber,
    required this.totalPages,
  });

  factory MatchmakerColleagueConversationsPageModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rows = parseMapList(json['data'])
        .map(MatchmakerColleagueConversationModel.fromJson)
        .toList(growable: false);
    return MatchmakerColleagueConversationsPageModel(
      items: rows,
      pageNumber: parseInt(json['pageNumber'], fallback: 1),
      totalPages: parseInt(json['totalPages'], fallback: 1),
    );
  }

  MatchmakerConversationsPage toEntity() => MatchmakerConversationsPage(
        items: items.map((m) => m.toEntity()).toList(growable: false),
        pageNumber: pageNumber,
        totalPages: totalPages,
      );
}
