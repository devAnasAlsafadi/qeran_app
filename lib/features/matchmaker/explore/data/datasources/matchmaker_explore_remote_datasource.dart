import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/api_response.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../../discovery/data/models/discovery_filter_question_model.dart';
import '../explore_query_builder.dart';
import '../models/matchmaker_explore_page_model.dart';

abstract interface class MatchmakerExploreRemoteDataSource {
  /// One page of explore results, filtered by [search] / [gender] /
  /// [questionFilters] (`QuestionFilters[id]=comma-joined`).
  Future<MatchmakerExplorePageModel> getExplore({
    required int page,
    required int pageSize,
    String? search,
    Gender? gender,
    Map<int, List<String>> questionFilters,
  });

  /// The active filter questions (same shape + parser as discovery's /filters).
  Future<List<DiscoveryFilterQuestionModel>> getFilters();
}

class MatchmakerExploreRemoteDataSourceImpl
    implements MatchmakerExploreRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const MatchmakerExploreRemoteDataSourceImpl({required ApiConsumer apiConsumer})
      : _apiConsumer = apiConsumer;

  @override
  Future<MatchmakerExplorePageModel> getExplore({
    required int page,
    required int pageSize,
    String? search,
    Gender? gender,
    Map<int, List<String>> questionFilters = const {},
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      ...buildExploreQuery(
        search: search,
        gender: gender,
        questionFilters: questionFilters,
      ),
    };
    AppLogger.debug(
      'MATCHMAKER — explore page=$page size=$pageSize '
      'filters=${query.length - 2}',
      tag: 'MATCHMAKER',
    );
    final response = await _apiConsumer.get(
      EndPoints.matchmakerExplore,
      queryParameters: query,
    );
    final apiResponse = ApiResponse<MatchmakerExplorePageModel>.fromJson(
      response as Map<String, dynamic>,
      (json) =>
          MatchmakerExplorePageModel.fromJson(json as Map<String, dynamic>),
    );
    final data = apiResponse.data;
    if (data == null) {
      AppLogger.error(
        'MATCHMAKER — explore ok but data was null',
        tag: 'MATCHMAKER',
      );
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    return data;
  }

  @override
  Future<List<DiscoveryFilterQuestionModel>> getFilters() async {
    AppLogger.debug('MATCHMAKER — explore filters', tag: 'MATCHMAKER');
    final response = await _apiConsumer.get(EndPoints.matchmakerExploreFilters);
    final apiResponse = ApiResponse<List<DiscoveryFilterQuestionModel>>.fromJson(
      response as Map<String, dynamic>,
      (json) => (json as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DiscoveryFilterQuestionModel.fromJson)
          .toList(),
    );
    final data = apiResponse.data;
    if (data == null) {
      throw ServerException(
        message: apiResponse.message ?? LocaleKeys.errors_generic,
      );
    }
    return data;
  }
}
