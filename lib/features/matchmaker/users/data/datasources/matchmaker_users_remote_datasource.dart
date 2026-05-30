import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/api_response.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/matchmaker_users_list.dart';
import '../models/matchmaker_users_page_model.dart';

abstract interface class MatchmakerUsersRemoteDataSource {
  Future<MatchmakerUsersPageModel> getUsers({
    required MatchmakerUsersList list,
    required int page,
    required int pageSize,
  });
}

class MatchmakerUsersRemoteDataSourceImpl
    implements MatchmakerUsersRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const MatchmakerUsersRemoteDataSourceImpl({required ApiConsumer apiConsumer})
      : _apiConsumer = apiConsumer;

  @override
  Future<MatchmakerUsersPageModel> getUsers({
    required MatchmakerUsersList list,
    required int page,
    required int pageSize,
  }) async {
    final path = switch (list) {
      MatchmakerUsersList.pending => EndPoints.matchmakerUsersPending,
      MatchmakerUsersList.approvedUnsubscribed =>
        EndPoints.matchmakerUsersApprovedUnsubscribed,
      MatchmakerUsersList.approvedSubscribed =>
        EndPoints.matchmakerUsersApprovedSubscribed,
    };
    AppLogger.debug(
      'MATCHMAKER — get users ${list.name} page=$page size=$pageSize',
      tag: 'MATCHMAKER',
    );
    final response = await _apiConsumer.get(
      path,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    final apiResponse = ApiResponse<MatchmakerUsersPageModel>.fromJson(
      response as Map<String, dynamic>,
      (json) => MatchmakerUsersPageModel.fromJson(json as Map<String, dynamic>),
    );
    final data = apiResponse.data;
    if (data == null) {
      AppLogger.error(
        'MATCHMAKER — users ${list.name} ok but data was null',
        tag: 'MATCHMAKER',
      );
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    return data;
  }
}
