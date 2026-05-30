import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/api_response.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../models/matchmaker_dashboard_model.dart';

abstract interface class MatchmakerDashboardRemoteDataSource {
  Future<MatchmakerDashboardModel> getDashboard();
}

class MatchmakerDashboardRemoteDataSourceImpl
    implements MatchmakerDashboardRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const MatchmakerDashboardRemoteDataSourceImpl({
    required ApiConsumer apiConsumer,
  }) : _apiConsumer = apiConsumer;

  @override
  Future<MatchmakerDashboardModel> getDashboard() async {
    AppLogger.debug('MATCHMAKER — get dashboard', tag: 'MATCHMAKER');
    // `get` enforces the `status == 1` envelope and throws
    // `CodedServerException` otherwise (e.g. 401 → UNAUTHORIZED), which
    // the repository maps to a Failure. On success `data` is the stats
    // object.
    final response = await _apiConsumer.get(EndPoints.matchmakerDashboard);
    final apiResponse = ApiResponse<MatchmakerDashboardModel>.fromJson(
      response as Map<String, dynamic>,
      (json) => MatchmakerDashboardModel.fromJson(json as Map<String, dynamic>),
    );
    final data = apiResponse.data;
    if (data == null) {
      AppLogger.error(
        'MATCHMAKER — dashboard ok but data was null',
        tag: 'MATCHMAKER',
      );
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    return data;
  }
}
