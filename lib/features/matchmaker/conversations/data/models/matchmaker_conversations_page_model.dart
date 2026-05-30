import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/matchmaker_conversations_page.dart';
import 'matchmaker_conversation_model.dart';

/// Wire model for the paginated `data` object returned by the conversations
/// endpoint: `{ data: [...rows], pageNumber, pageSize, totalCount,
/// totalPages }` — the same shape as the M2b users / M3a cases pages. The
/// server already sorts rows by `lastMessageAt` DESC, so they render as-is.
class MatchmakerConversationsPageModel {
  final List<MatchmakerConversationModel> items;
  final int pageNumber;
  final int totalPages;

  const MatchmakerConversationsPageModel({
    required this.items,
    required this.pageNumber,
    required this.totalPages,
  });

  factory MatchmakerConversationsPageModel.fromJson(Map<String, dynamic> json) {
    final rows = parseMapList(json['data'])
        .map(MatchmakerConversationModel.fromJson)
        .toList(growable: false);
    return MatchmakerConversationsPageModel(
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
