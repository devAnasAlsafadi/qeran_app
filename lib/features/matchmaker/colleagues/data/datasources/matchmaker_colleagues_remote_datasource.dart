import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../shared/data/json_parsers.dart';
import '../../../shared/data/matchmaker_envelope.dart';
import '../models/matchmaker_colleague_conversations_page_model.dart';
import '../models/matchmaker_colleagues_page_model.dart';

abstract interface class MatchmakerColleaguesRemoteDataSource {
  /// The directory of colleagues to START a chat with.
  Future<MatchmakerColleaguesPageModel> getColleagues({
    required int page,
    required int pageSize,
  });

  /// Active colleague↔colleague threads (same envelope as user conversations).
  Future<MatchmakerColleagueConversationsPageModel> getColleagueConversations({
    required int page,
    required int pageSize,
  });

  /// Opens (or fetches) the conversation with colleague [colleagueId] via
  /// `POST /matchmaker/colleagues/{id}/open-chat` and returns its
  /// `conversationId`.
  Future<int> openColleagueChat(String colleagueId);
}

class MatchmakerColleaguesRemoteDataSourceImpl
    implements MatchmakerColleaguesRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const MatchmakerColleaguesRemoteDataSourceImpl({
    required ApiConsumer apiConsumer,
  }) : _apiConsumer = apiConsumer;

  @override
  Future<MatchmakerColleaguesPageModel> getColleagues({
    required int page,
    required int pageSize,
  }) async {
    AppLogger.debug(
      'MATCHMAKER — get colleagues page=$page size=$pageSize',
      tag: 'MATCHMAKER',
    );
    final response = await _apiConsumer.get(
      EndPoints.matchmakerColleagues,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    // `get()` enforced the OUTER envelope (status == 1). The directory payload
    // may be a bare array OR a paginated object; the model tolerates both. A
    // double-wrapped Map is unwrapped first so a future shape parses unchanged.
    final raw = (response as Map<String, dynamic>)['data'];
    final payload =
        raw is Map<String, dynamic> ? (unwrapInnerEnvelope(raw) ?? raw) : raw;
    return MatchmakerColleaguesPageModel.fromData(payload);
  }

  @override
  Future<MatchmakerColleagueConversationsPageModel> getColleagueConversations({
    required int page,
    required int pageSize,
  }) async {
    AppLogger.debug(
      'MATCHMAKER — get colleague conversations page=$page size=$pageSize',
      tag: 'MATCHMAKER',
    );
    final response = await _apiConsumer.get(
      EndPoints.matchmakerConversationsColleagues,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    final pageJson =
        unwrapInnerEnvelope((response as Map<String, dynamic>)['data']);
    if (pageJson == null) {
      AppLogger.error(
        'MATCHMAKER — colleague conversations ok but data was null',
        tag: 'MATCHMAKER',
      );
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    return MatchmakerColleagueConversationsPageModel.fromJson(pageJson);
  }

  @override
  Future<int> openColleagueChat(String colleagueId) async {
    AppLogger.debug(
      'MATCHMAKER — open chat with colleague $colleagueId',
      tag: 'MATCHMAKER',
    );
    final response = await _apiConsumer.post(
      EndPoints.matchmakerColleagueOpenChat(colleagueId),
    );
    // `post()` enforced the OUTER envelope (status == 1). Tolerate both a raw
    // int (`data: 123`) and a wrapped object (`data: {conversationId: 123}`).
    final data = (response as Map<String, dynamic>)['data'];
    final conversationId = parseNullableInt(data) ??
        parseNullableInt(parseNullableMap(data)?['conversationId']);
    if (conversationId == null) {
      AppLogger.error(
        'MATCHMAKER — open colleague chat ok but no conversationId',
        tag: 'MATCHMAKER',
      );
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    return conversationId;
  }
}
