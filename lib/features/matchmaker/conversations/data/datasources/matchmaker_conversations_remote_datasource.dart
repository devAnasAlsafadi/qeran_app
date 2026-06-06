import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../shared/data/json_parsers.dart';
import '../../../shared/data/matchmaker_envelope.dart';
import '../models/matchmaker_conversations_page_model.dart';

abstract interface class MatchmakerConversationsRemoteDataSource {
  Future<MatchmakerConversationsPageModel> getUserConversations({
    required int page,
    required int pageSize,
  });

  /// Lazily opens (or fetches) the matchmaker↔user conversation for [userId]
  /// via `GET /matchmaker/users/{id}/chat` and returns its `conversationId`.
  Future<int> openChatWithUser(String userId);
}

class MatchmakerConversationsRemoteDataSourceImpl
    implements MatchmakerConversationsRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const MatchmakerConversationsRemoteDataSourceImpl({
    required ApiConsumer apiConsumer,
  }) : _apiConsumer = apiConsumer;

  @override
  Future<MatchmakerConversationsPageModel> getUserConversations({
    required int page,
    required int pageSize,
  }) async {
    AppLogger.debug(
      'MATCHMAKER — get user conversations page=$page size=$pageSize',
      tag: 'MATCHMAKER',
    );
    final response = await _apiConsumer.get(
      EndPoints.matchmakerConversationsUsers,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    // `get()` enforced the OUTER envelope (status == 1). Single-wrapped today,
    // but route the payload through unwrapInnerEnvelope so a future
    // double-wrap parses unchanged (a map with no `status` key is returned
    // as-is).
    final pageJson =
        unwrapInnerEnvelope((response as Map<String, dynamic>)['data']);
    if (pageJson == null) {
      AppLogger.error(
        'MATCHMAKER — user conversations ok but data was null',
        tag: 'MATCHMAKER',
      );
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    return MatchmakerConversationsPageModel.fromJson(pageJson);
  }

  @override
  Future<int> openChatWithUser(String userId) async {
    AppLogger.debug(
      'MATCHMAKER — open chat with user $userId',
      tag: 'MATCHMAKER',
    );
    final response = await _apiConsumer.get(
      EndPoints.matchmakerUserChat(userId),
    );
    // `get()` enforced the OUTER envelope (status == 1). The endpoint doc says
    // the payload is the conversationId — tolerate both a raw int
    // (`data: 123`) and a wrapped object (`data: {conversationId: 123}`).
    final data = (response as Map<String, dynamic>)['data'];
    final conversationId = parseNullableInt(data) ??
        parseNullableInt(parseNullableMap(data)?['conversationId']);
    if (conversationId == null) {
      AppLogger.error(
        'MATCHMAKER — open chat ok but no conversationId in data',
        tag: 'MATCHMAKER',
      );
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    return conversationId;
  }
}
