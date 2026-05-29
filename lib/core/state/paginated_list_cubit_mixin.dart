import 'package:flutter_bloc/flutter_bloc.dart';

import 'paginated_list_state.dart';

/// Mixin for cubits that own a single paginated list of `T`.
///
/// Implementers provide [fetchPage] returning `(items, hasMore)` for a
/// 1-indexed page. The mixin handles page bookkeeping, refresh vs
/// load-more flag separation, and error capture; loaders never overlap.
mixin PaginatedListCubitMixin<T> on Cubit<PaginatedListState<T>> {
  /// Page size sent to the backend. Override per cubit if needed.
  int get pageSize => 20;

  /// Performs the network call for [page] and returns the fresh items
  /// plus whether more pages exist. Throws on failure — the mixin
  /// captures the message into `errorMessage`.
  Future<({List<T> items, bool hasMore})> fetchPage(int page);

  /// First load. Safe to call repeatedly — does nothing while another
  /// load is in flight.
  Future<void> loadFirst() async {
    if (state.isLoading || state.isRefreshing) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final result = await fetchPage(1);
      emit(state.copyWith(
        items: result.items,
        page: 1,
        hasMore: result.hasMore,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Pull-to-refresh. Keeps existing items visible until the new page
  /// arrives, then replaces them atomically.
  Future<void> refresh() async {
    if (state.isRefreshing || state.isLoading) return;
    emit(state.copyWith(isRefreshing: true, clearError: true));
    try {
      final result = await fetchPage(1);
      emit(state.copyWith(
        items: result.items,
        page: 1,
        hasMore: result.hasMore,
        isRefreshing: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isRefreshing: false,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Load the next page (no-op when nothing more to load or another
  /// load is already running).
  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isLoading || state.isRefreshing) return;
    if (!state.hasMore) return;
    final nextPage = state.page + 1;
    emit(state.copyWith(isLoadingMore: true, clearError: true));
    try {
      final result = await fetchPage(nextPage);
      emit(state.copyWith(
        items: [...state.items, ...result.items],
        page: nextPage,
        hasMore: result.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      ));
    }
  }
}
