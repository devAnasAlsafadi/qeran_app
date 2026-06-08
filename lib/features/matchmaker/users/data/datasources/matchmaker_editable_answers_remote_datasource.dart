import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';

import '../../../shared/data/matchmaker_envelope.dart';

/// Datasource for the matchmaker's text-answer SAVE (`POST …/text-answer`).
/// The read-side listing was removed with the standalone editable-answers
/// screen (PV4) — editing is now inline on the profile.
abstract interface class MatchmakerEditableAnswersRemoteDataSource {
  Future<String> updateTextAnswer({
    required String userId,
    required int questionId,
    required String textAnswer,
  });
}

class MatchmakerEditableAnswersRemoteDataSourceImpl
    implements MatchmakerEditableAnswersRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const MatchmakerEditableAnswersRemoteDataSourceImpl({
    required ApiConsumer apiConsumer,
  }) : _apiConsumer = apiConsumer;

  @override
  Future<String> updateTextAnswer({
    required String userId,
    required int questionId,
    required String textAnswer,
  }) async {
    AppLogger.debug(
      'MATCHMAKER — update text-answer $userId q=$questionId',
      tag: 'MATCHMAKER',
    );
    final response = await _apiConsumer.postRaw(
      EndPoints.matchmakerUserTextAnswer(userId),
      body: {'questionId': questionId, 'textAnswer': textAnswer},
    );
    return mutationResultText(response);
  }
}
