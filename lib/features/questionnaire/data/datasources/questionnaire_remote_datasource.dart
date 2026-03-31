import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/core/errors/exceptions.dart';
import '../../../../core/api/api_response.dart';
import '../models/question_model.dart';

abstract interface class QuestionnaireRemoteDataSource {
  Future<List<QuestionModel>> fetchQuestions({required Gender gender});
}

class QuestionnaireRemoteDataSourceImpl implements QuestionnaireRemoteDataSource {
  final ApiConsumer _apiConsumer;

  QuestionnaireRemoteDataSourceImpl({required ApiConsumer apiConsumer})
      : _apiConsumer = apiConsumer;









  @override
  Future<List<QuestionModel>> fetchQuestions({required Gender gender}) async {
    AppLogger.debug(
      'FETCH QUESTIONS -> gender: ${gender.apiValue}',
      tag: 'QUESTIONNAIRE',
    );

    final response = await _apiConsumer.get(
      EndPoints.questions,
      queryParameters: {'gender': gender.apiValue},
    );

    final apiResponse = ApiResponse<List<QuestionModel>>.fromJson(
      response,
          (json) {
        final questionsList = json['questions'] as List<dynamic>? ?? [];
        return questionsList
            .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
            .toList();
      },
    );

    if (apiResponse.data == null) {
      throw ServerException(message: apiResponse.message ?? 'فشل تحميل الأسئلة');
    }

    AppLogger.info(
      'Parsed ${apiResponse.data!.length} questions from response',
      tag: 'QUESTIONNAIRE',
    );

    return apiResponse.data!;
  }
}
