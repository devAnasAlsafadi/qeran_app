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

  /// `totalCount` from the wire — how many users match the whole query, not
  /// how many rows this page carries.
  ///
  /// Nullable rather than `?? 0`: the envelope has always documented this
  /// field but the client never read it, so it is unverified in practice. A
  /// zero fallback would be indistinguishable from a genuine "no matches" and
  /// would render "found 0 results" over a full list if the field were absent.
  /// Null means "unknown" and the UI shows nothing.
  final int? totalCount;

  const MatchmakerExplorePageModel({
    required this.items,
    required this.pageNumber,
    required this.totalPages,
    this.totalCount,
  });

  factory MatchmakerExplorePageModel.fromJson(Map<String, dynamic> json) {
    final rows = parseMapList(json['data'])
        .map(MatchmakerExploreUserModel.fromJson)
        .toList(growable: false);
    return MatchmakerExplorePageModel(
      items: rows,
      pageNumber: parseInt(json['pageNumber'], fallback: 1),
      totalPages: parseInt(json['totalPages'], fallback: 1),
      totalCount: parseNullableInt(json['totalCount']),
    );
  }

  MatchmakerExplorePage toEntity() => MatchmakerExplorePage(
        items: items.map((m) => m.toEntity()).toList(growable: false),
        pageNumber: pageNumber,
        totalPages: totalPages,
        totalCount: totalCount,
      );
}
