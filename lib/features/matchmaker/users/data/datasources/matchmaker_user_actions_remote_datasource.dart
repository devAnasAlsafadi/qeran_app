import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';

import '../../../shared/data/matchmaker_envelope.dart';

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

  /// These endpoints carry the result text in `data` (a String) with an
  /// empty `message`, so we go through `postRaw` and classify via
  /// [mutationResultText] — `status == 1` is success regardless of the
  /// data/message split, and a failure surfaces the non-empty text. See
  /// `matchmaker_envelope.dart`.
  Future<String> _mutate(
    String path, {
    required String action,
    Object? body,
  }) async {
    AppLogger.debug('MATCHMAKER — $action', tag: 'MATCHMAKER');
    final response = await _apiConsumer.postRaw(path, body: body);
    return mutationResultText(response);
  }
}
