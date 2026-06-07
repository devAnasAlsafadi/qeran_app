import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/matchmaker_colleagues_page.dart';
import 'matchmaker_colleague_model.dart';

/// Wire model for the colleague directory payload. The OLD doc shows the
/// response as a bare array `[{...}]`, yet the endpoint takes `page`/`pageSize`
/// — so this tolerates BOTH shapes:
///   • a bare array            → collapsed to a single page
///   • a paginated object      → `{ data:[...], pageNumber, totalPages }`
/// matching the proven users / cases / conversations page envelope.
class MatchmakerColleaguesPageModel {
  final List<MatchmakerColleagueModel> items;
  final int pageNumber;
  final int totalPages;

  const MatchmakerColleaguesPageModel({
    required this.items,
    required this.pageNumber,
    required this.totalPages,
  });

  /// [data] is the already-unwrapped payload (`response['data']`, or its inner
  /// envelope's data) — either a `List` or a paginated `Map`.
  factory MatchmakerColleaguesPageModel.fromData(Object? data) {
    if (data is List) {
      return MatchmakerColleaguesPageModel(
        items: parseMapList(data)
            .map(MatchmakerColleagueModel.fromJson)
            .toList(growable: false),
        pageNumber: 1,
        totalPages: 1,
      );
    }
    final map = parseNullableMap(data) ?? const <String, dynamic>{};
    return MatchmakerColleaguesPageModel(
      items: parseMapList(map['data'])
          .map(MatchmakerColleagueModel.fromJson)
          .toList(growable: false),
      pageNumber: parseInt(map['pageNumber'], fallback: 1),
      totalPages: parseInt(map['totalPages'], fallback: 1),
    );
  }

  MatchmakerColleaguesPage toEntity() => MatchmakerColleaguesPage(
        items: items.map((m) => m.toEntity()).toList(growable: false),
        pageNumber: pageNumber,
        totalPages: totalPages,
      );
}
