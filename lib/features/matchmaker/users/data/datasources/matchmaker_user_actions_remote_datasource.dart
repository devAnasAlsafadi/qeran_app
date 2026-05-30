import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../shared/data/json_parsers.dart';

abstract interface class MatchmakerUserActionsRemoteDataSource {
  Future<String> approve(String userId);
  Future<String> reject({required String userId, required String reason});
  Future<String> requestImage(String userId);
}

class MatchmakerUserActionsRemoteDataSourceImpl
    implements MatchmakerUserActionsRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const MatchmakerUserActionsRemoteDataSourceImpl({
    required ApiConsumer apiConsumer,
  }) : _apiConsumer = apiConsumer;

  @override
  Future<String> approve(String userId) =>
      _mutate(EndPoints.matchmakerUserApprove(userId), action: 'approve');

  @override
  Future<String> reject({required String userId, required String reason}) =>
      _mutate(
        EndPoints.matchmakerUserReject(userId),
        action: 'reject',
        body: {'reason': reason},
      );

  @override
  Future<String> requestImage(String userId) => _mutate(
        EndPoints.matchmakerUserRequestImage(userId),
        action: 'request-image',
      );

  /// Shared mutation runner. These endpoints answer with the human-readable
  /// result in the `data` field (a String) and an empty `message`, so we go
  /// through `postRaw`: the `status == 1` gate of `post` would turn a
  /// classified failure into a transport error and discard that text.
  /// `status == 1` is success regardless of the data/message split; on
  /// failure we surface whichever of `data` / `message` is non-empty,
  /// falling back to a generic localized error.
  Future<String> _mutate(
    String path, {
    required String action,
    Object? body,
  }) async {
    AppLogger.debug('MATCHMAKER — $action', tag: 'MATCHMAKER');
    final response = await _apiConsumer.postRaw(path, body: body);
    if (response is! Map<String, dynamic>) {
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    final status = response['status'];
    final text = _firstNonEmpty([
      parseNullableString(response['data']),
      parseNullableString(response['message']),
    ]);
    if (status == 1 || status == true) {
      return text ?? '';
    }
    throw CodedServerException(
      message: text ?? LocaleKeys.errors_generic,
      errorCode: parseNullableString(response['errorCode']),
    );
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }
}
