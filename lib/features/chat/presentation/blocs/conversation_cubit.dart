import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:uuid/uuid.dart';

import 'package:qeran/core/app_logger.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/message_send_status.dart';
import '../../domain/entities/messages_read_event.dart';
import '../../domain/entities/realtime_status.dart';
import '../../domain/entities/send_text_outcome.dart';
import '../../domain/entities/share_profile_outcome.dart';
import '../../domain/ports/chat_realtime_port.dart';
import '../../domain/usecases/get_conversation_messages_usecase.dart';
import '../../domain/usecases/mark_conversation_as_read_usecase.dart';
import '../../domain/usecases/send_text_message_usecase.dart';
import '../../domain/usecases/share_profile_usecase.dart';
import 'conversation_state.dart';

/// Screen-scoped controller for one open conversation.
///
/// Phase-8 scope wires the `ChatRealtimePort`. After the initial REST
/// load succeeds, we connect to SignalR and subscribe to
/// `incomingMessages` + `statusStream`. Each incoming row is routed
/// through the same id-based dedup gate the optimistic pipeline uses,
/// so duplicates from REST + SignalR (rare race per backend docs) can
/// never produce two visible bubbles. On a `reconnecting → connected`
/// transition we fetch page 1 and merge by id to recover any messages
/// missed during the gap.
class ConversationCubit extends Cubit<ConversationStateData> with SafeEmit<ConversationStateData> {
  static const int _initialPageSize = 30;
  static const int _olderPageSize = 30;
  static const int messageMaxLength = 2000;

  /// Local backoff windows in response to backend 429s. Pure UX cap;
  /// the server is the real authority.
  static const Duration _sendCooldownAfter429 = Duration(seconds: 10);
  static const Duration _shareCooldownAfter429 = Duration(seconds: 30);

  final GetConversationMessagesUseCase _getMessages;
  final MarkConversationAsReadUseCase _markAsRead;
  final SendTextMessageUseCase _sendText;
  final ShareProfileUseCase _shareProfile;
  final ChatRealtimePort _realtimePort;

  /// Source of truth for "who is me" when stamping optimistic temps
  /// and computing `isMine` rendering. Provided by the screen at
  /// create-time from `UserSessionCubit`.
  final String myUserId;

  /// Uuid generator for `clientTempId`s. Override in tests if needed.
  final Uuid _uuid;

  StreamSubscription<ChatMessage>? _incomingSub;
  StreamSubscription<RealtimeStatus>? _statusSub;
  StreamSubscription<MessagesReadEvent>? _messagesReadSub;
  bool _realtimeWired = false;

  ConversationCubit({
    required int conversationId,
    required this.myUserId,
    required GetConversationMessagesUseCase getMessages,
    required MarkConversationAsReadUseCase markAsRead,
    required SendTextMessageUseCase sendText,
    required ShareProfileUseCase shareProfile,
    required ChatRealtimePort realtimePort,
    Uuid? uuid,
  })  : _getMessages = getMessages,
        _markAsRead = markAsRead,
        _sendText = sendText,
        _shareProfile = shareProfile,
        _realtimePort = realtimePort,
        _uuid = uuid ?? const Uuid(),
        super(ConversationStateData(conversationId: conversationId));

  // ── Initial load + pagination + refresh ───────────────────────────

  Future<void> init() async {
    emit(state.copyWith(
      initialStatus: ConversationAsyncStatus.loading,
      clearLoadError: true,
    ));
    final result = await _getMessages(
      conversationId: state.conversationId,
      page: 1,
      pageSize: _initialPageSize,
    );
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'CHAT — initial load failed conv=${state.conversationId} '
          'raw="${failure.message}"',
          tag: 'CHAT',
        );
        emit(state.copyWith(
          initialStatus: ConversationAsyncStatus.failure,
          loadErrorKey: failure.message,
        ));
      },
      (page) {
        final ids = page.messages
            .map((m) => m.serverId)
            .whereType<int>()
            .toSet();
        emit(state.copyWith(
          initialStatus: ConversationAsyncStatus.loaded,
          messages: _sortNewestFirst(page.messages),
          hasMore: page.hasMore,
          currentPage: page.pageNumber,
          seenServerIds: ids,
          clearLoadError: true,
        ));
        _maybeMarkAsRead();
        _wireRealtimeOnce();
      },
    );
  }

  // ── Realtime wiring ───────────────────────────────────────────────

  /// Subscribe to the realtime port exactly once per cubit lifetime.
  /// Idempotent across `refresh()` calls.
  ///
  /// Deliberately does NOT open the session: the shell owns it (see
  /// `ChatRealtimeHost`), because the hub carries traffic for every tab
  /// and must outlive any one conversation. Connecting here as well
  /// would not be a harmless duplicate — `connect()` tears down the live
  /// session before opening a new one, so a second caller churns the
  /// socket and republishes the whole status cycle, which this cubit
  /// reads as a drop and answers with a needless page=1 refetch.
  void _wireRealtimeOnce() {
    if (_realtimeWired) return;
    _realtimeWired = true;
    _incomingSub = _realtimePort.incomingMessages.listen(_onIncomingMessage);
    _statusSub = _realtimePort.statusStream.listen(_onRealtimeStatus);
    _messagesReadSub =
        _realtimePort.messagesRead.listen(_onMessagesRead);
    // Seed from the port's CURRENT status. The shell almost always
    // connected long before this screen opened, and that `connected`
    // event is already spent — a broadcast stream does not replay it.
    // Without this the header would read "not active" over a perfectly
    // live socket, and `hasEverBeenConnected` would stay false,
    // disarming the catch-up rule for the rest of the conversation.
    _onRealtimeStatus(_realtimePort.status);
  }

  void _onIncomingMessage(ChatMessage msg) {
    if (isClosed) return;
    // Defensive: only handle events for this conversation.
    if (msg.conversationId != state.conversationId) return;
    final id = msg.serverId;
    // Dedup: an id already in the seen set means we have this row
    // (either from REST or a prior SignalR delivery). Drop silently.
    if (id != null && state.seenServerIds.contains(id)) return;
    final mergedIds = id == null
        ? state.seenServerIds
        : <int>{...state.seenServerIds, id};
    final next = _sortNewestFirst(<ChatMessage>[msg, ...state.messages]);
    emit(state.copyWith(messages: next, seenServerIds: mergedIds));
    // If the new message is from the matchmaker AND we're on screen,
    // mark the conversation as read so the unread count returns to 0.
    if (msg.senderId != myUserId) {
      _maybeMarkAsRead();
    }
  }

  /// Backend fires `MessagesRead` to the OTHER side of a conversation
  /// when that side calls `MarkAsRead`. We use it to flip `isRead` on
  /// our outgoing messages so the screen can render the subtle "Read"
  /// micro-label under the last outgoing read message.
  ///
  /// Defensive: drop events for a different conversation, and ignore
  /// self-triggered reads (per backend Q12, the server doesn't echo
  /// to the actor — but we guard regardless).
  void _onMessagesRead(MessagesReadEvent event) {
    if (isClosed) return;
    if (event.conversationId != state.conversationId) return;
    if (event.readByUserId == myUserId) return;
    var anyChanged = false;
    final updated = <ChatMessage>[];
    for (final m in state.messages) {
      if (m.senderId == myUserId && m.serverId != null && !m.isRead) {
        updated.add(m.copyWith(isRead: true));
        anyChanged = true;
      } else {
        updated.add(m);
      }
    }
    if (!anyChanged) return;
    emit(state.copyWith(messages: updated));
    AppLogger.info(
      'CHAT — flipped outgoing isRead via MessagesRead '
      'conv=${state.conversationId} byUser=${event.readByUserId}',
      tag: 'CHAT',
    );
  }

  void _onRealtimeStatus(RealtimeStatus next) {
    if (isClosed) return;
    final prev = state.realtimeStatus;
    // Catch-up triggers on ANY re-entry into `connected` after we've
    // previously been connected. Covers both auto-reconnect after a
    // network blip (prev=reconnecting) AND resume-from-background
    // (prev=disconnected → connecting → connected). The initial
    // connect never triggers because `hasEverBeenConnected` is still
    // false at that point — REST page=1 already loaded inline.
    final shouldCatchUp = state.hasEverBeenConnected &&
        next == RealtimeStatus.connected &&
        prev != RealtimeStatus.connected;
    emit(state.copyWith(
      realtimeStatus: next,
      hasEverBeenConnected: state.hasEverBeenConnected ||
          next == RealtimeStatus.connected,
    ));
    if (shouldCatchUp) {
      // Backend confirmed: SignalR does NOT replay missed messages.
      // Fetch page=1 and merge by id to recover anything we missed.
      unawaited(_catchUpAfterReconnect());
    }
  }

  Future<void> _catchUpAfterReconnect() async {
    final result = await _getMessages(
      conversationId: state.conversationId,
      page: 1,
      pageSize: _initialPageSize,
    );
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'CHAT — reconnect catch-up failed conv=${state.conversationId} '
          'raw="${failure.message}"',
          tag: 'CHAT',
        );
      },
      (page) {
        final mergedIds = <int>{...state.seenServerIds};
        final merged = <ChatMessage>[...state.messages];
        for (final m in page.messages) {
          final id = m.serverId;
          if (id == null || mergedIds.contains(id)) continue;
          mergedIds.add(id);
          merged.add(m);
        }
        emit(state.copyWith(
          messages: _sortNewestFirst(merged),
          seenServerIds: mergedIds,
        ));
        AppLogger.info(
          'CHAT — reconnect catch-up merged conv=${state.conversationId}',
          tag: 'CHAT',
        );
      },
    );
  }

  Future<void> refresh() => init();

  Future<void> loadMore() async {
    if (state.isPaginating) return;
    if (!state.hasMore) return;
    emit(state.copyWith(isPaginating: true, paginationFailed: false));
    final next = state.currentPage + 1;
    final result = await _getMessages(
      conversationId: state.conversationId,
      page: next,
      pageSize: _olderPageSize,
    );
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'CHAT — pagination failed conv=${state.conversationId} '
          'page=$next raw="${failure.message}"',
          tag: 'CHAT',
        );
        emit(state.copyWith(isPaginating: false, paginationFailed: true));
      },
      (page) {
        final mergedIds = {...state.seenServerIds};
        final merged = <ChatMessage>[...state.messages];
        for (final m in page.messages) {
          final id = m.serverId;
          if (id == null || mergedIds.contains(id)) continue;
          mergedIds.add(id);
          merged.add(m);
        }
        emit(state.copyWith(
          messages: _sortNewestFirst(merged),
          hasMore: page.hasMore,
          currentPage: page.pageNumber,
          isPaginating: false,
          seenServerIds: mergedIds,
        ));
      },
    );
  }

  Future<void> retryPagination() => loadMore();

  // ── Send text — optimistic ────────────────────────────────────────

  /// Insert an optimistic temp immediately, then fire REST. On
  /// success replace the temp with the server-confirmed message; on
  /// failure leave the temp visible with `status: failed` so the
  /// user can retry by tapping the bubble.
  Future<void> sendText(String rawContent) async {
    final content = rawContent.trim();
    if (content.isEmpty) {
      _publishEvent(ConversationEvent.sendValidationEmpty);
      return;
    }
    if (content.length > messageMaxLength) {
      _publishEvent(ConversationEvent.sendValidationTooLong);
      return;
    }
    if (_isInSendCooldown()) {
      _publishEvent(ConversationEvent.sendRateLimited);
      return;
    }
    final clientTempId = _uuid.v4();
    _insertOptimisticTemp(clientTempId: clientTempId, content: content);
    final result = await _sendText(
      conversationId: state.conversationId,
      content: content,
    );
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'CHAT — send transport failure conv=${state.conversationId} '
          'tempId=$clientTempId raw="${failure.message}"',
          tag: 'CHAT',
        );
        _markTempFailed(clientTempId);
        // Event published for parity with the typed-outcome failure
        // path. The screen's listener drops it on the floor (the
        // failed bubble's tap-to-retry is the visible affordance);
        // tests / analytics still see the transition.
        _publishEvent(ConversationEvent.sendFailure);
      },
      (outcome) => _onSendTextOutcome(outcome, clientTempId),
    );
  }

  /// Retry a previously-failed outgoing message. The failed temp is
  /// removed and a fresh `sendText` call runs (creating a new temp
  /// with a new `clientTempId`).
  Future<void> retryFailedSend(ChatMessage failed) async {
    if (failed.status != MessageSendStatus.failed) return;
    final tempId = failed.clientTempId;
    if (tempId == null) return;
    _removeTemp(tempId);
    await sendText(failed.content);
  }

  void _onSendTextOutcome(SendTextOutcome outcome, String clientTempId) {
    switch (outcome) {
      case SendTextSuccess(:final message):
        _reconcileTempWithServer(clientTempId, message);
      case SendTextValidationError():
        // Server rejected after local validation passed — drop the
        // temp (it would otherwise sit "sending" forever) and emit.
        _removeTemp(clientTempId);
        _publishEvent(ConversationEvent.sendValidationEmpty);
      case SendTextConversationNotFound():
        _markTempFailed(clientTempId);
        _publishEvent(ConversationEvent.sendConversationNotFound);
      case SendTextUnauthorized():
        _markTempFailed(clientTempId);
        _publishEvent(ConversationEvent.sendUnauthorized);
      case SendTextRateLimited():
        // The server rate-limited us. Drop the temp so it doesn't sit
        // in a sending state, set cooldown, emit.
        _removeTemp(clientTempId);
        emit(state.copyWith(
          sendCooldownUntil: DateTime.now().add(_sendCooldownAfter429),
        ));
        _publishEvent(ConversationEvent.sendRateLimited);
      case SendTextFailure():
        _markTempFailed(clientTempId);
        _publishEvent(ConversationEvent.sendFailure);
    }
  }

  // ── Share profile — non-optimistic (per design) ───────────────────

  Future<void> shareProfile(String sharedUserId) async {
    final id = sharedUserId.trim();
    if (id.isEmpty) {
      _publishEvent(ConversationEvent.shareValidation);
      return;
    }
    final result = await _shareProfile(
      conversationId: state.conversationId,
      sharedUserId: id,
    );
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'CHAT — share transport failure conv=${state.conversationId} '
          'raw="${failure.message}"',
          tag: 'CHAT',
        );
        _publishEvent(ConversationEvent.shareFailure);
      },
      _onShareProfileOutcome,
    );
  }

  void _onShareProfileOutcome(ShareProfileOutcome outcome) {
    switch (outcome) {
      case ShareProfileSuccess(:final message):
        _insertServerMessage(message);
        _publishEvent(ConversationEvent.shareSuccess);
      case ShareProfileNotFound():
        _publishEvent(ConversationEvent.shareProfileNotFound);
      case ShareProfileValidationError():
        _publishEvent(ConversationEvent.shareValidation);
      case ShareProfileConversationNotFound():
        _publishEvent(ConversationEvent.shareConversationNotFound);
      case ShareProfileUnauthorized():
        _publishEvent(ConversationEvent.shareUnauthorized);
      case ShareProfileRateLimited():
        emit(state.copyWith(
          sendCooldownUntil:
              DateTime.now().add(_shareCooldownAfter429),
        ));
        _publishEvent(ConversationEvent.shareRateLimited);
      case ShareProfileFailure():
        _publishEvent(ConversationEvent.shareFailure);
    }
  }

  // ── Optimistic temp helpers ───────────────────────────────────────

  void _insertOptimisticTemp({
    required String clientTempId,
    required String content,
  }) {
    final temp = ChatMessage(
      serverId: null,
      clientTempId: clientTempId,
      conversationId: state.conversationId,
      senderId: myUserId,
      // `senderName` isn't rendered for outgoing bubbles, so an empty
      // string is fine. Reconciliation will overwrite this with the
      // server's value on success.
      senderName: '',
      content: content,
      sharedProfile: null,
      isRead: false,
      sentAt: DateTime.now().toUtc(),
      status: MessageSendStatus.sending,
    );
    // Prepend (newest-first list) so the bubble appears at the
    // visible bottom of the reversed `ListView` immediately.
    emit(state.copyWith(messages: [temp, ...state.messages]));
  }

  /// Replace the temp identified by [clientTempId] with the server's
  /// confirmed [serverMsg]. If a row with the same `serverId` is
  /// already present (rare reconnect-replay race), drop the temp.
  void _reconcileTempWithServer(String clientTempId, ChatMessage serverMsg) {
    final serverId = serverMsg.serverId;
    if (serverId != null && state.seenServerIds.contains(serverId)) {
      _removeTemp(clientTempId);
      return;
    }
    final updated = <ChatMessage>[];
    var replaced = false;
    for (final m in state.messages) {
      if (!replaced && m.clientTempId == clientTempId) {
        updated.add(serverMsg);
        replaced = true;
      } else {
        updated.add(m);
      }
    }
    if (!replaced) {
      // Defensive: temp was already gone (close-mid-flight cleanup?).
      // Treat as a fresh server insert so we never silently lose the
      // confirmed message.
      updated.add(serverMsg);
    }
    final mergedIds = serverId == null
        ? state.seenServerIds
        : {...state.seenServerIds, serverId};
    emit(state.copyWith(
      messages: _sortNewestFirst(updated),
      seenServerIds: mergedIds,
    ));
  }

  void _markTempFailed(String clientTempId) {
    final updated = state.messages.map((m) {
      if (m.clientTempId == clientTempId) {
        return m.copyWith(status: MessageSendStatus.failed);
      }
      return m;
    }).toList(growable: false);
    emit(state.copyWith(messages: updated));
  }

  void _removeTemp(String clientTempId) {
    final updated = state.messages
        .where((m) => m.clientTempId != clientTempId)
        .toList(growable: false);
    emit(state.copyWith(messages: updated));
  }

  // ── Internals ──────────────────────────────────────────────────────

  bool _isInSendCooldown() {
    final until = state.sendCooldownUntil;
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  void _insertServerMessage(ChatMessage msg) {
    final id = msg.serverId;
    if (id != null && state.seenServerIds.contains(id)) return;
    final mergedIds =
        id == null ? state.seenServerIds : {...state.seenServerIds, id};
    final next = _sortNewestFirst([...state.messages, msg]);
    emit(state.copyWith(messages: next, seenServerIds: mergedIds));
  }

  void _publishEvent(ConversationEvent event) {
    emit(state.copyWith(
      event: event,
      eventVersion: state.eventVersion + 1,
    ));
  }

  /// Stable newest-first ordering with `id` tie-breaker per backend
  /// guidance (rare same-millisecond `sentAt` collisions). Optimistic
  /// temps lack a `serverId` so they tie-break to the front of their
  /// timestamp bucket via the `-1` fallback.
  List<ChatMessage> _sortNewestFirst(Iterable<ChatMessage> messages) {
    final list = messages.toList();
    list.sort((a, b) {
      final c = b.sentAt.compareTo(a.sentAt);
      if (c != 0) return c;
      return (b.serverId ?? -1).compareTo(a.serverId ?? -1);
    });
    return list;
  }

  void _maybeMarkAsRead() {
    final hasUnreadInbound =
        state.messages.any((m) => !m.isRead && m.senderId != myUserId);
    if (!hasUnreadInbound) return;
    _markAsRead(state.conversationId).then((result) {
      result.fold(
        (failure) => AppLogger.warning(
          'CHAT — mark-as-read failed conv=${state.conversationId} '
          'raw="${failure.message}"',
          tag: 'CHAT',
        ),
        (_) => AppLogger.info(
          'CHAT — marked as read conv=${state.conversationId}',
          tag: 'CHAT',
        ),
      );
    });
  }

  @override
  Future<void> close() async {
    await _incomingSub?.cancel();
    _incomingSub = null;
    await _statusSub?.cancel();
    _statusSub = null;
    await _messagesReadSub?.cancel();
    _messagesReadSub = null;
    // Drops the subscriptions ONLY. The session belongs to the shell and
    // has to survive leaving a conversation — every other tab's badge
    // rides it.
    await super.close();
  }
}
