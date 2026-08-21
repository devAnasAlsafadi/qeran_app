import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/api_response.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../models/matchmaker_notifications_page_model.dart';

abstract interface class MatchmakerNotificationsRemoteDataSource {
  Future<MatchmakerNotificationsPageModel> getNotifications({
    required int page,
    required int pageSize,
  });
}

class MatchmakerNotificationsRemoteDataSourceImpl
    implements MatchmakerNotificationsRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const MatchmakerNotificationsRemoteDataSourceImpl({
    required ApiConsumer apiConsumer,
  }) : _apiConsumer = apiConsumer;

  @override
  Future<MatchmakerNotificationsPageModel> getNotifications({
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
    final apiResponse =
        ApiResponse<MatchmakerNotificationsPageModel>.fromJson(
      response as Map<String, dynamic>,
      (json) =>
          MatchmakerNotificationsPageModel.fromData(json, pageSize: pageSize),
    );
    final data = apiResponse.data;
    if (data == null) {
      AppLogger.error('NOTIFICATIONS — ok but data null', tag: 'NOTIFICATIONS');
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    return data;
  }
}
