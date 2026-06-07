import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/matchmaker_explore_page.dart';
import 'matchmaker_explore_user_model.dart';

/// Wire model for the paginated `data` object returned by
/// `GET /api/matchmaker/explore`:
/// `{ data: [...rows], totalCount, pageNumber, pageSize, totalPages }` — the
/// same envelope as the users / cases pages.
class MatchmakerExplorePageModel {
  final List<MatchmakerExploreUserModel> items;
  final int pageNumber;
  final int totalPages;

  const MatchmakerExplorePageModel({
    required this.items,
    required this.pageNumber,
    required this.totalPages,
  });

  factory MatchmakerExplorePageModel.fromJson(Map<String, dynamic> json) {
    final rows = parseMapList(json['data'])
        .map(MatchmakerExploreUserModel.fromJson)
        .toList(growable: false);
    return MatchmakerExplorePageModel(
      items: rows,
      pageNumber: parseInt(json['pageNumber'], fallback: 1),
      totalPages: parseInt(json['totalPages'], fallback: 1),
    );
  }

  MatchmakerExplorePage toEntity() => MatchmakerExplorePage(
        items: items.map((m) => m.toEntity()).toList(growable: false),
        pageNumber: pageNumber,
        totalPages: totalPages,
      );
}
