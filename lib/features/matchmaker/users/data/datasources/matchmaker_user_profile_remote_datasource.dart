import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../shared/data/json_parsers.dart';
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
    // `get()` already enforced the OUTER envelope (status == 1). This
    // endpoint is double-wrapped: response['data'] is itself another
    // {status, data, message, errorCode} envelope whose `data` holds the
    // profile. Unwrap once more — tolerant of a future flatten.
    final map = response as Map<String, dynamic>;
    final profileJson = _unwrapProfile(map['data']);
    if (profileJson == null) {
      AppLogger.error(
        'MATCHMAKER — profile $userId ok but body was empty',
        tag: 'MATCHMAKER',
      );
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    return MatchmakerUserProfileModel.fromJson(profileJson);
  }

  /// Reaches the profile object inside the double envelope.
  ///
  /// [outerData] is `response['data']`. In the current shape that's the
  /// inner `{status, data, message, errorCode}` envelope, so the profile
  /// lives at `outerData['data']`. If the backend later flattens the
  /// response, [outerData] is already the profile — detected by its own
  /// fields. An inner failure (e.g. `PROFILE_NOT_FOUND`) is surfaced as a
  /// [CodedServerException] so the repository maps it to a Failure like any
  /// other.
  Map<String, dynamic>? _unwrapProfile(Object? outerData) {
    if (outerData is! Map<String, dynamic>) return null;
    // Already the profile (flattened / future shape)?
    if (outerData.containsKey('userId') ||
        outerData.containsKey('placements')) {
      return outerData;
    }
    // Otherwise it's the inner envelope — honour its status, then unwrap.
    final innerStatus = outerData['status'];
    if (innerStatus is int && innerStatus != 1) {
      final message = parseNullableString(outerData['message']);
      throw CodedServerException(
        message: (message == null || message.isEmpty)
            ? LocaleKeys.errors_generic
            : message,
        errorCode: parseNullableString(outerData['errorCode']),
      );
    }
    final inner = outerData['data'];
    return inner is Map<String, dynamic> ? inner : null;
  }
}
