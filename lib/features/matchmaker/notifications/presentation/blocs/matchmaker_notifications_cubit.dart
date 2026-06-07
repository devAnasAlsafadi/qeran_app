import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/paginated_list_cubit_mixin.dart';
import 'package:qeran/core/state/paginated_list_state.dart';

import '../../domain/entities/matchmaker_notification.dart';
import '../../domain/usecases/get_notifications_usecase.dart';

/// Owns the paginated notification inbox. Pagination/refresh/load-more come
/// from [PaginatedListCubitMixin]; this class only wires the fetch.
class MatchmakerNotificationsCubit
    extends Cubit<PaginatedListState<MatchmakerNotification>>
    with PaginatedListCubitMixin<MatchmakerNotification> {
  final GetNotificationsUseCase _getNotifications;

  MatchmakerNotificationsCubit({
    required GetNotificationsUseCase getNotifications,
  })  : _getNotifications = getNotifications,
        super(const PaginatedListState());

  @override
  Future<({List<MatchmakerNotification> items, bool hasMore})> fetchPage(
    int page,
  ) async {
    final result = await _getNotifications(page: page, pageSize: pageSize);
    return result.fold(
      (failure) => throw _NotificationsFetchException(failure.message),
      (pageData) => (items: pageData.items, hasMore: pageData.hasMore),
    );
  }
}

class _NotificationsFetchException implements Exception {
  const _NotificationsFetchException(this.message);
  final String message;
  @override
  String toString() => message;
}
