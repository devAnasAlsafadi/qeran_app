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

  const PaginatedListState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.errorMessage,
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
  }) {
    return PaginatedListState<T>(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
