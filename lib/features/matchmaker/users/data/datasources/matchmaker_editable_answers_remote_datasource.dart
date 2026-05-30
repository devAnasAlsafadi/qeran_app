import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../shared/data/matchmaker_envelope.dart';
import '../models/matchmaker_editable_answers_page_model.dart';

abstract interface class MatchmakerEditableAnswersRemoteDataSource {
  Future<MatchmakerEditableAnswersPageModel> getEditableAnswers({
    required String userId,
    required int page,
    required int pageSize,
  });

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
  Future<MatchmakerEditableAnswersPageModel> getEditableAnswers({
    required String userId,
    required int page,
    required int pageSize,
  }) async {
    AppLogger.debug(
      'MATCHMAKER — editable answers $userId page=$page size=$pageSize',
      tag: 'MATCHMAKER',
    );
    final response = await _apiConsumer.get(
      EndPoints.matchmakerUserEditableAnswers(userId),
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    // Double-wrapped (same as profile detail): unwrap the inner envelope
    // to reach the PagedResult.
    final pageJson =
        unwrapInnerEnvelope((response as Map<String, dynamic>)['data']);
    if (pageJson == null) {
      AppLogger.error(
        'MATCHMAKER — editable answers $userId ok but body was empty',
        tag: 'MATCHMAKER',
      );
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    return MatchmakerEditableAnswersPageModel.fromJson(pageJson);
  }

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
