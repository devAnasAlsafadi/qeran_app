import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/matchmaker_users_page.dart';
import 'matchmaker_user_row_model.dart';

/// Wire model for the paginated `data` object returned by the three
/// user-list endpoints:
/// `{ data: [...rows], totalCount, pageNumber, pageSize, totalPages }`.
class MatchmakerUsersPageModel {
  final List<MatchmakerUserRowModel> items;
  final int pageNumber;
  final int totalPages;

  const MatchmakerUsersPageModel({
    required this.items,
    required this.pageNumber,
    required this.totalPages,
  });

  factory MatchmakerUsersPageModel.fromJson(Map<String, dynamic> json) {
    final rows = parseMapList(json['data'])
        .map(MatchmakerUserRowModel.fromJson)
        .toList(growable: false);
    return MatchmakerUsersPageModel(
      items: rows,
      pageNumber: parseInt(json['pageNumber'], fallback: 1),
      totalPages: parseInt(json['totalPages'], fallback: 1),
    );
  }

  MatchmakerUsersPage toEntity() => MatchmakerUsersPage(
        items: items.map((m) => m.toEntity()).toList(growable: false),
        pageNumber: pageNumber,
        totalPages: totalPages,
      );
}
