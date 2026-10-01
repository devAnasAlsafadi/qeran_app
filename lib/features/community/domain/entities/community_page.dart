import 'package:equatable/equatable.dart';

/// One page of a Community list — the server's PagedResult (1-based pages).
/// Posts and comments arrive newest first, replies oldest first; callers
/// de-duplicate by id, because a new item shifts the later pages.
class CommunityPage<T> extends Equatable {
  final List<T> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const CommunityPage({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  bool get hasMore => pageNumber < totalPages;

  @override
  List<Object?> get props =>
      [items, pageNumber, pageSize, totalCount, totalPages];
}
