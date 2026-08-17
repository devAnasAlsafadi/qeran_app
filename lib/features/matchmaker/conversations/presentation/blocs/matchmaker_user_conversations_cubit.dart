import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/core/state/paginated_list_cubit_mixin.dart';
import 'package:qeran/core/state/paginated_list_state.dart';

import '../../../shared/domain/entities/matchmaker_realtime_status.dart';
import '../../../shared/domain/entities/received_chat_message.dart';
import '../../../shared/domain/ports/matchmaker_realtime_port.dart';
import '../../domain/entities/matchmaker_conversation.dart';
import '../../domain/usecases/get_user_conversations_usecase.dart';

/// Owns the paginated list of the matchmaker's conversations with users.
/// Pagination/refresh/load-more come from [PaginatedListCubitMixin]; this
/// class also wires the matchmaker realtime port (4c-2):
///   • `ReceiveMessage` → bump the matched row's preview + timestamp,
///     increment unread for INBOUND messages, and re-sort newest-first.
///     An unknown conversationId triggers a refresh (a brand-new
///     conversation can't be synthesised from the message alone).
///   • realtime reconnect → re-fetch page 1 to catch up on anything missed
///     while the socket was down (SignalR does not replay missed events).
///
/// The connection itself is owned by the matchmaker shell, never by this
/// cubit. The shell's `IndexedStack` keeps this cubit alive across tab
/// switches, so the list updates live while on any tab.
class MatchmakerUserConversationsCubit
    extends Cubit<PaginatedListState<MatchmakerConversation>>
    with SafeEmit<PaginatedListState<MatchmakerConversation>>, PaginatedListCubitMixin<MatchmakerConversation> {
  final GetUserConversationsUseCase _getConversations;
  final MatchmakerRealtimePort _realtimePort;

  /// Current user's id — distinguishes self-sent (no unread bump) from
  /// inbound messages. Provided by the screen from `UserSessionCubit`.
  final String _myUserId;

  StreamSubscription<ReceivedChatMessage>? _incomingSub;
  StreamSubscription<MatchmakerRealtimeStatus>? _statusSub;
  bool _hasBeenConnected;

  MatchmakerUserConversationsCubit({
    required GetUserConversationsUseCase getConversations,
    required MatchmakerRealtimePort realtimePort,
    required String myUserId,
  })  : _getConversations = getConversations,
        _realtimePort = realtimePort,
        _myUserId = myUserId,
        _hasBeenConnected =
            realtimePort.status == MatchmakerRealtimeStatus.connected,
        super(const PaginatedListState()) {
    _incomingSub = _realtimePort.incomingMessages.listen(_onIncoming);
    _statusSub = _realtimePort.statusStream.listen(_onStatus);
  }

  @override
  Future<({List<MatchmakerConversation> items, bool hasMore})> fetchPage(
    int page,
  ) async {
    final result = await _getConversations(page: page, pageSize: pageSize);
    return result.fold(
      (failure) => throw _ConversationsFetchException(failure.message),
      (pageData) => (items: pageData.items, hasMore: pageData.hasMore),
    );
  }

  /// Apply a live inbound/outbound message to the loaded list. Self-sent
  /// (`senderId == myUserId`) updates the preview only; inbound also bumps
  /// unread. Unknown conversationId → refresh to pull the new row in.
  void _onIncoming(ReceivedChatMessage msg) {
    if (isClosed) return;
    final index =
        state.items.indexWhere((c) => c.conversationId == msg.conversationId);
    if (index < 0) {
      refresh();
      return;
    }
    final existing = state.items[index];
    final inbound = msg.senderId != _myUserId;
    // The localization signal travels through untouched — the card resolves
    // it at build so a language switch repaints the row.
    final updated = existing.withLastMessage(
      preview: msg.contentPreview,
      at: msg.sentAt ?? existing.lastMessageAt,
      unreadCount: inbound ? existing.unreadCount + 1 : existing.unreadCount,
      type: msg.type,
      contentAr: msg.contentAr,
      contentEn: msg.contentEn,
    );
    final items = [...state.items]..[index] = updated;
    _sortNewestFirst(items);
    emit(state.copyWith(items: items));
  }

  /// Clear a single conversation's unread badge in place — called when the
  /// matchmaker returns from that thread (the chat marks it read on open). A
  /// local, zero-network update so the inbox is NOT re-fetched on every open;
  /// live updates to other rows already flow through [_onIncoming]. No-op for
  /// an unknown / off-page id, or one already at zero.
  void markConversationRead(int conversationId) {
    if (isClosed) return;
    final index =
        state.items.indexWhere((c) => c.conversationId == conversationId);
    if (index < 0 || state.items[index].unreadCount == 0) return;
    emit(state.copyWith(
      items: [...state.items]
        ..[index] = state.items[index].copyWith(unreadCount: 0),
    ));
  }

  /// Reconnect catch-up (4c-1 pattern): on re-entry into `connected` after
  /// a prior connection, re-fetch page 1. The first-ever connect never
  /// triggers this (the list's initial `loadFirst` covers it).
  void _onStatus(MatchmakerRealtimeStatus status) {
    if (isClosed) return;
    final shouldCatchUp =
        _hasBeenConnected && status == MatchmakerRealtimeStatus.connected;
    if (status == MatchmakerRealtimeStatus.connected) {
      _hasBeenConnected = true;
    }
    if (shouldCatchUp) refresh();
  }

  /// Newest-first by `lastMessageAt`, mirroring the server order; rows with
  /// a null timestamp sort last.
  void _sortNewestFirst(List<MatchmakerConversation> items) {
    items.sort((a, b) {
      final at = a.lastMessageAt;
      final bt = b.lastMessageAt;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });
  }

  @override
  Future<void> close() async {
    await _incomingSub?.cancel();
    _incomingSub = null;
    await _statusSub?.cancel();
    _statusSub = null;
    // The realtime connection is owned by the matchmaker shell — cancel our
    // subscriptions only, never disconnect the port here.
    await super.close();
  }
}

class _ConversationsFetchException implements Exception {
  const _ConversationsFetchException(this.message);
  final String message;
  @override
  String toString() => message;
}
