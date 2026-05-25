import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/my_matchmaker_outcome.dart';
import '../../domain/entities/send_text_outcome.dart';
import '../../domain/entities/share_profile_outcome.dart';
import '../error_codes.dart';
import '../models/chat_message_model.dart';
import '../models/chat_messages_page_model.dart';
import '../models/conversation_model.dart';
import '../models/matchmaker_info_model.dart';

abstract interface class ChatRemoteDataSource {
  Future<MyMatchmakerOutcome> getMyMatchmaker();
  Future<List<ConversationModel>> getConversations();
  Future<ChatMessagesPageModel> getMessages({
    required int conversationId,
    required int page,
    required int pageSize,
  });
  Future<SendTextOutcome> sendTextMessage({
    required int conversationId,
    required String content,
  });
  Future<ShareProfileOutcome> shareProfile({
    required int conversationId,
    required String sharedUserId,
  });
  Future<void> markAsRead(int conversationId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const ChatRemoteDataSourceImpl({required ApiConsumer apiConsumer})
      : _apiConsumer = apiConsumer;

  // ── Bootstrap ──────────────────────────────────────────────────────

  @override
  Future<MyMatchmakerOutcome> getMyMatchmaker() async {
    AppLogger.debug('CHAT — get my-matchmaker', tag: 'CHAT');
    try {
      final body = await _apiConsumer.getRaw(EndPoints.chatMyMatchmaker);
      // Backend uses status:0 + data:null for the not-assigned state
      // — getRaw doesn't enforce status==1, so we inspect the
      // envelope ourselves and route to the right typed outcome.
      if (body is Map<String, dynamic>) {
        final ok = body['status'] == 1 || body['status'] == true;
        final message = _envelopeMessage(body);
        if (!ok) {
          AppLogger.info(
            'CHAT — my-matchmaker not assigned message="$message"',
            tag: 'CHAT',
          );
          return MyMatchmakerNotAssigned(serverMessage: message);
        }
        final data = body['data'];
        if (data is! Map<String, dynamic>) {
          AppLogger.error(
            'CHAT — my-matchmaker ok but data shape unexpected: '
            '${data.runtimeType}',
            tag: 'CHAT',
          );
          throw ServerException(message: LocaleKeys.errors_generic);
        }
        final info = MatchmakerInfoModel.fromJson(data).toEntity();
        AppLogger.info(
          'CHAT — my-matchmaker assigned conversationId=${info.conversationId}',
          tag: 'CHAT',
        );
        return MyMatchmakerAssigned(info: info);
      }
      AppLogger.error(
        'CHAT — my-matchmaker unexpected body type=${body.runtimeType}',
        tag: 'CHAT',
      );
      throw ServerException(message: LocaleKeys.errors_generic);
    } on ServerException catch (e) {
      final code = e is CodedServerException ? e.errorCode : null;
      AppLogger.warning(
        'CHAT — my-matchmaker failed code="$code" message="${e.message}"',
        tag: 'CHAT',
      );
      return MyMatchmakerFailure(serverMessage: e.message, errorCode: code);
    }
  }

  // ── Conversations list (future-proof) ──────────────────────────────

  @override
  Future<List<ConversationModel>> getConversations() async {
    AppLogger.debug('CHAT — get conversations', tag: 'CHAT');
    final body = await _apiConsumer.getRaw(EndPoints.chatConversations);
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map(ConversationModel.fromJson)
          .toList(growable: false);
    }
    if (body is Map<String, dynamic>) {
      if (body.containsKey('status') || body.containsKey('data')) {
        final ok = body['status'] == 1 || body['status'] == true;
        if (!ok) {
          throw ServerException(message: LocaleKeys.errors_generic);
        }
        final data = body['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map(ConversationModel.fromJson)
              .toList(growable: false);
        }
      }
    }
    AppLogger.error(
      'CHAT — conversations unexpected body type=${body.runtimeType}',
      tag: 'CHAT',
    );
    throw ServerException(message: LocaleKeys.errors_generic);
  }

  // ── Messages ───────────────────────────────────────────────────────

  @override
  Future<ChatMessagesPageModel> getMessages({
    required int conversationId,
    required int page,
    required int pageSize,
  }) async {
    AppLogger.debug(
      'CHAT — get messages conv=$conversationId page=$page size=$pageSize',
      tag: 'CHAT',
    );
    final body = await _apiConsumer.getRaw(
      EndPoints.chatMessages(conversationId),
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    if (body is! Map<String, dynamic>) {
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    if (body.containsKey('status') || body.containsKey('data')) {
      final ok = body['status'] == 1 || body['status'] == true;
      if (!ok) {
        throw ServerException(message: LocaleKeys.errors_generic);
      }
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw ServerException(message: LocaleKeys.errors_generic);
      }
      return ChatMessagesPageModel.fromJson(data);
    }
    // Direct shape fallback.
    return ChatMessagesPageModel.fromJson(body);
  }

  // ── Send text ──────────────────────────────────────────────────────

  @override
  Future<SendTextOutcome> sendTextMessage({
    required int conversationId,
    required String content,
  }) async {
    AppLogger.debug(
      'CHAT — send text conv=$conversationId len=${content.length}',
      tag: 'CHAT',
    );
    try {
      final body = await _apiConsumer.postRaw(
        EndPoints.chatSendMessage(conversationId),
        body: {'content': content},
      );
      if (body is Map<String, dynamic>) {
        final ok = body['status'] == 1 || body['status'] == true;
        final message = _envelopeMessage(body);
        if (!ok) {
          final code = body['errorCode'] as String?;
          return _classifySendText(message, code);
        }
        final data = body['data'];
        if (data is! Map<String, dynamic>) {
          throw ServerException(message: LocaleKeys.errors_generic);
        }
        final msg = ChatMessageModel.fromJson(data).toEntity();
        AppLogger.info(
          'CHAT — send text accepted conv=$conversationId id=${msg.serverId}',
          tag: 'CHAT',
        );
        return SendTextSuccess(message: msg);
      }
      throw ServerException(message: LocaleKeys.errors_generic);
    } on ServerException catch (e) {
      final code = e is CodedServerException ? e.errorCode : null;
      final outcome = _classifySendText(e.message, code, statusCodeHint: e);
      if (outcome is SendTextFailure) {
        AppLogger.warning(
          'CHAT — send text unmapped conv=$conversationId code="$code" '
          'message="${e.message}"',
          tag: 'CHAT',
        );
        rethrow;
      }
      return outcome;
    }
  }

  // ── Share profile ──────────────────────────────────────────────────

  @override
  Future<ShareProfileOutcome> shareProfile({
    required int conversationId,
    required String sharedUserId,
  }) async {
    AppLogger.debug(
      'CHAT — share profile conv=$conversationId user=$sharedUserId',
      tag: 'CHAT',
    );
    try {
      final body = await _apiConsumer.postRaw(
        EndPoints.chatShareProfile(conversationId),
        body: {'sharedUserId': sharedUserId},
      );
      if (body is Map<String, dynamic>) {
        final ok = body['status'] == 1 || body['status'] == true;
        final message = _envelopeMessage(body);
        if (!ok) {
          final code = body['errorCode'] as String?;
          return _classifyShareProfile(message, code);
        }
        final data = body['data'];
        if (data is! Map<String, dynamic>) {
          throw ServerException(message: LocaleKeys.errors_generic);
        }
        final msg = ChatMessageModel.fromJson(data).toEntity();
        return ShareProfileSuccess(message: msg);
      }
      throw ServerException(message: LocaleKeys.errors_generic);
    } on ServerException catch (e) {
      final code = e is CodedServerException ? e.errorCode : null;
      final outcome = _classifyShareProfile(e.message, code, statusCodeHint: e);
      if (outcome is ShareProfileFailure) {
        AppLogger.warning(
          'CHAT — share profile unmapped conv=$conversationId code="$code" '
          'message="${e.message}"',
          tag: 'CHAT',
        );
        rethrow;
      }
      return outcome;
    }
  }

  // ── Mark as read ───────────────────────────────────────────────────

  @override
  Future<void> markAsRead(int conversationId) async {
    AppLogger.debug('CHAT — mark as read conv=$conversationId', tag: 'CHAT');
    await _apiConsumer.postRaw(EndPoints.chatMarkAsRead(conversationId));
  }

  // ── Classification helpers ─────────────────────────────────────────

  SendTextOutcome _classifySendText(
    String rawMessage,
    String? errorCode, {
    ServerException? statusCodeHint,
  }) {
    // Rate-limit is HTTP 429 from AspNetCoreRateLimit — the http
    // consumer surfaces it as the locale-key string `errors.too_many_requests`.
    if (statusCodeHint != null &&
        statusCodeHint.message == LocaleKeys.errors_too_many_requests) {
      return SendTextRateLimited(serverMessage: rawMessage);
    }
    if (errorCode != null && errorCode.isNotEmpty) {
      switch (errorCode) {
        case ChatErrorCodes.validationError:
          return SendTextValidationError(serverMessage: rawMessage);
        case ChatErrorCodes.conversationNotFound:
          return SendTextConversationNotFound(serverMessage: rawMessage);
        case ChatErrorCodes.unauthorized:
          return SendTextUnauthorized(serverMessage: rawMessage);
      }
    }
    return SendTextFailure(
      serverMessage: rawMessage,
      errorCode: errorCode,
    );
  }

  ShareProfileOutcome _classifyShareProfile(
    String rawMessage,
    String? errorCode, {
    ServerException? statusCodeHint,
  }) {
    if (statusCodeHint != null &&
        statusCodeHint.message == LocaleKeys.errors_too_many_requests) {
      return ShareProfileRateLimited(serverMessage: rawMessage);
    }
    if (errorCode != null && errorCode.isNotEmpty) {
      switch (errorCode) {
        case ChatErrorCodes.profileNotFound:
          return ShareProfileNotFound(serverMessage: rawMessage);
        case ChatErrorCodes.validationError:
          return ShareProfileValidationError(serverMessage: rawMessage);
        case ChatErrorCodes.conversationNotFound:
          return ShareProfileConversationNotFound(serverMessage: rawMessage);
        case ChatErrorCodes.unauthorized:
          return ShareProfileUnauthorized(serverMessage: rawMessage);
      }
    }
    return ShareProfileFailure(
      serverMessage: rawMessage,
      errorCode: errorCode,
    );
  }

  String _envelopeMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      final raw = body['message'];
      if (raw is String) return raw;
    }
    return '';
  }
}
