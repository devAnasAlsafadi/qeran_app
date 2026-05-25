import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/domain/entities/success_response.dart';
import '../models/question_category_model.dart';
import '../models/question_model.dart';

abstract interface class QuestionnaireRemoteDataSource {
  Future<List<QuestionModel>> fetchQuestions({required Gender gender});
  Future<dynamic> submitAnswers({required List<Map<String, dynamic>> answers});
}

class QuestionnaireRemoteDataSourceImpl
    implements QuestionnaireRemoteDataSource {
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

    final apiResponse = ApiResponse<List<QuestionModel>>.fromJson(response, (
      json,
    ) {
      // 'data' is now a List of category objects — flatten into a single
      // List<QuestionModel> with categoryName injected into each model.
      final categoriesList = json as List<dynamic>;
      return categoriesList
          .map((c) => QuestionCategoryModel.fromJson(c as Map<String, dynamic>))
          .expand((category) => category.questions)
          .toList();
    });

    if (apiResponse.data == null) {
      throw ServerException(
        message: apiResponse.message ?? LocaleKeys.errors_questions_load_failed,
      );
    }

    AppLogger.info(
      'Parsed ${apiResponse.data!.length} questions from response',
      tag: 'QUESTIONNAIRE',
    );

    return apiResponse.data!;
  }

  @override
  Future<SuccessResponse<dynamic>> submitAnswers({
    required List<Map<String, dynamic>> answers,
  }) async {
    AppLogger.debug(
      'SUBMIT ANSWERS -> count: ${answers.length}',
      tag: 'QUESTIONNAIRE',
    );

    final response = await _apiConsumer.post(
      EndPoints.submitAnswers,
      body: {'answers': answers},
    );

    final apiResponse = ApiResponse<dynamic>.fromJson(response, (json) => json);

    return SuccessResponse.fromApiResponse(apiResponse);
  }
}
