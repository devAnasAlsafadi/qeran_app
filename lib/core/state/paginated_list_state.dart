/// Generic paginated-list state shared by every Matchmaker list cubit.
///
/// Holds the accumulated items, the current page (1-indexed), a
/// `hasMore` flag, plus orthogonal `isRefreshing` / `isLoadingMore`
/// flags so the UI can show the right indicator without overwriting
/// already-rendered items. `errorMessage` is a hint surface — the
/// cubit chooses whether a load failure clears items or just sets
/// the message and keeps the previous page visible.
class PaginatedListState<T> {
  final List<T> items;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? errorMessage;

  /// Size of the WHOLE result set matching the current server query, as
  /// reported by the backend — deliberately NOT the same concept as
  /// `items.length`:
  ///
  ///   • [items].length — how many rows are loaded on the client right now.
  ///     Grows as the user scrolls and pages are appended. Only ever equals
  ///     the total once every page has been fetched.
  ///   • [totalCount]   — how many rows exist on the server for this query.
  ///     Constant while scrolling; changes only when the query (filter) or
  ///     the underlying data changes.
  ///
  /// Never display `items.length` as a total, and never fall back to it when
  /// this is null — they answer different questions and only coincide by
  /// accident on a short list.
  ///
  /// Null means the server did not report a total (field absent, or the list
  /// has not loaded yet). Render "unknown", not 0.
  final int? totalCount;

  const PaginatedListState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.totalCount,
  });

  bool get isInitial =>
      items.isEmpty && !isLoading && !isRefreshing && errorMessage == null;

  PaginatedListState<T> copyWith({
    List<T>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
    int? totalCount,
    bool clearTotalCount = false,
  }) {
    return PaginatedListState<T>(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      // Explicit clear, because a server that stops reporting a total must be
      // able to reset this to unknown — `?? this.totalCount` alone would pin
      // the last known number forever.
      totalCount: clearTotalCount ? null : (totalCount ?? this.totalCount),
    );
  }
}
