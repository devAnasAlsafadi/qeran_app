import '../../domain/entities/community_page.dart';
import '../json_parsers.dart';

/// Wire model for a PagedResult — the `data` the datasource peels from the
/// envelope: `{ data: [...], pageNumber, pageSize, totalCount, totalPages }`.
/// One generic model for posts, comments and replies; entries that aren't
/// objects are dropped.
class CommunityPageModel<M> {
  final List<M> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const CommunityPageModel({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory CommunityPageModel.fromJson(
    Map<String, dynamic> json,
    M Function(Map<String, dynamic> json) parseItem,
  ) =>
      CommunityPageModel(
        items: parseMapList(json['data']).map(parseItem).toList(growable: false),
        pageNumber: parseInt(json['pageNumber'], fallback: 1),
        pageSize: parseInt(json['pageSize']),
        totalCount: parseInt(json['totalCount']),
        totalPages: parseInt(json['totalPages']),
      );

  CommunityPage<E> toEntity<E>(E Function(M model) convert) => CommunityPage(
        items: items.map(convert).toList(growable: false),
        pageNumber: pageNumber,
        pageSize: pageSize,
        totalCount: totalCount,
        totalPages: totalPages,
      );
}
