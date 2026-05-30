import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/matchmaker_editable_answers_page.dart';
import 'matchmaker_editable_answer_model.dart';

/// Parses the standard PagedResult wrapper
/// `{ data[], pageNumber, pageSize, totalCount, totalPages }`. The
/// datasource unwraps the double envelope before this runs.
class MatchmakerEditableAnswersPageModel {
  final List<MatchmakerEditableAnswerModel> items;
  final int pageNumber;
  final int totalPages;

  const MatchmakerEditableAnswersPageModel({
    required this.items,
    required this.pageNumber,
    required this.totalPages,
  });

  factory MatchmakerEditableAnswersPageModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final raw = json['data'];
    final items = raw is List
        ? raw
            .whereType<Map<String, dynamic>>()
            .map(MatchmakerEditableAnswerModel.fromJson)
            .toList(growable: false)
        : const <MatchmakerEditableAnswerModel>[];
    return MatchmakerEditableAnswersPageModel(
      items: items,
      pageNumber: parseInt(json['pageNumber'], fallback: 1),
      totalPages: parseInt(json['totalPages'], fallback: 1),
    );
  }

  MatchmakerEditableAnswersPage toEntity() => MatchmakerEditableAnswersPage(
        items: items.map((i) => i.toEntity()).toList(growable: false),
        pageNumber: pageNumber,
        totalPages: totalPages,
      );
}
