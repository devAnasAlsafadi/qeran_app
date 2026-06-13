import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/api_response.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../json_parsers.dart';
import '../models/notifications_page_model.dart';

abstract interface class NotificationsRemoteDataSource {
  Future<NotificationsPageModel> getNotifications({
    required int page,
    required int pageSize,
  });

  /// Total notification count (not unread — the backend has no read-state).
  Future<int> getCount();
}

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const NotificationsRemoteDataSourceImpl({required ApiConsumer apiConsumer})
      : _apiConsumer = apiConsumer;

  @override
  Future<NotificationsPageModel> getNotifications({
    required int page,
    required int pageSize,
  }) async {
    AppLogger.debug(
      'NOTIFICATIONS — get page=$page size=$pageSize',
      tag: 'NOTIFICATIONS',
    );
    final response = await _apiConsumer.get(
      EndPoints.notifications,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    final apiResponse = ApiResponse<NotificationsPageModel>.fromJson(
      response as Map<String, dynamic>,
      (json) => NotificationsPageModel.fromData(json, pageSize: pageSize),
    );
    final data = apiResponse.data;
    if (data == null) {
      AppLogger.error('NOTIFICATIONS — ok but data null', tag: 'NOTIFICATIONS');
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    return data;
  }

  @override
  Future<int> getCount() async {
    AppLogger.debug('NOTIFICATIONS — get count', tag: 'NOTIFICATIONS');
    final response = await _apiConsumer.get(EndPoints.notificationsCount);
    // `get()` enforced the OUTER envelope. data is `{count: N}` — tolerate a
    // raw int too.
    final data = (response as Map<String, dynamic>)['data'];
    return parseNullableInt(data) ??
        parseInt(parseNullableMap(data)?['count']);
  }
}
