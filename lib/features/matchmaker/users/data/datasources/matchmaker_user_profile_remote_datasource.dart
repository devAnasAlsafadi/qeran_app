import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../shared/data/matchmaker_envelope.dart';
import '../models/matchmaker_user_profile_model.dart';

abstract interface class MatchmakerUserProfileRemoteDataSource {
  Future<MatchmakerUserProfileModel> getUserProfile(String userId);
}

class MatchmakerUserProfileRemoteDataSourceImpl
    implements MatchmakerUserProfileRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const MatchmakerUserProfileRemoteDataSourceImpl({
    required ApiConsumer apiConsumer,
  }) : _apiConsumer = apiConsumer;

  @override
  Future<MatchmakerUserProfileModel> getUserProfile(String userId) async {
    AppLogger.debug('MATCHMAKER — get user profile $userId', tag: 'MATCHMAKER');
    final response = await _apiConsumer.get(
      EndPoints.matchmakerUserProfile(userId),
    );
    // `get()` enforced the OUTER envelope (status == 1). This endpoint
    // double-wraps, so unwrap the inner {status, data, message, errorCode}
    // envelope once more to reach the profile — tolerant of a future
    // flatten (see `unwrapInnerEnvelope`).
    final profileJson =
        unwrapInnerEnvelope((response as Map<String, dynamic>)['data']);
    if (profileJson == null) {
      AppLogger.error(
        'MATCHMAKER — profile $userId ok but body was empty',
        tag: 'MATCHMAKER',
      );
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    // TEMPORARY DIAGNOSTIC (M2) — remove once read. Distinguishes "the
    // AddImageRequestStatus migration isn't applied" (key ABSENT) from "the
    // client isn't re-reading it" (key PRESENT with a value).
    AppLogger.info(
      'DIAG profile $userId imageRequestStatus '
      'present=${profileJson.containsKey('imageRequestStatus')} '
      'value=${profileJson['imageRequestStatus']}',
      tag: 'MATCHMAKER',
    );
    return MatchmakerUserProfileModel.fromJson(profileJson);
  }
}
