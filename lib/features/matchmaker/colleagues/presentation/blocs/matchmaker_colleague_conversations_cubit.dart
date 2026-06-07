import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/paginated_list_cubit_mixin.dart';
import 'package:qeran/core/state/paginated_list_state.dart';

import '../../../conversations/domain/entities/matchmaker_conversation.dart';
import '../../../shared/domain/entities/matchmaker_realtime_status.dart';
import '../../../shared/domain/entities/received_chat_message.dart';
import '../../../shared/domain/ports/matchmaker_realtime_port.dart';
import '../../domain/usecases/get_colleague_conversations_usecase.dart';

/// Owns the paginated list of the matchmaker's conversations with COLLEAGUES.
/// A direct clone of `MatchmakerUserConversationsCubit` — colleague threads
/// use the same generic [MatchmakerConversation] entity and flow through the
/// same realtime hub (type `MatchmakerToMatchmaker`):
///   • `ReceiveMessage` → bump the matched row's preview + timestamp,
///     increment unread for INBOUND messages, and re-sort newest-first.
///     An unknown conversationId triggers a refresh.
///   • realtime reconnect → re-fetch page 1 to catch up on missed events.
///
/// The connection is owned by the matchmaker shell, never by this cubit. The
/// shell's `IndexedStack` keeps the cubit alive across tab switches.
class MatchmakerColleagueConversationsCubit
    extends Cubit<PaginatedListState<MatchmakerConversation>>
    with PaginatedListCubitMixin<MatchmakerConversation> {
  final GetColleagueConversationsUseCase _getConversations;
  final MatchmakerRealtimePort _realtimePort;

  /// Current user's id — distinguishes self-sent (no unread bump) from
  /// inbound messages. Provided by the screen from `UserSessionCubit`.
  final String _myUserId;

  StreamSubscription<ReceivedChatMessage>? _incomingSub;
  StreamSubscription<MatchmakerRealtimeStatus>? _statusSub;
  bool _hasBeenConnected;

  MatchmakerColleagueConversationsCubit({
    required GetColleagueConversationsUseCase getConversations,
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
      (failure) => throw _ColleagueConversationsFetchException(failure.message),
      (pageData) => (items: pageData.items, hasMore: pageData.hasMore),
    );
  }

  /// Apply a live inbound/outbound message to the loaded list. Self-sent
  /// updates the preview only; inbound also bumps unread. Unknown
  /// conversationId → refresh to pull the new row in.
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
    final updated = existing.copyWith(
      lastMessagePreview: msg.contentPreview,
      lastMessageAt: msg.sentAt ?? existing.lastMessageAt,
      unreadCount: inbound ? existing.unreadCount + 1 : existing.unreadCount,
    );
    final items = [...state.items]..[index] = updated;
    _sortNewestFirst(items);
    emit(state.copyWith(items: items));
  }

  /// Reconnect catch-up: on re-entry into `connected` after a prior
  /// connection, re-fetch page 1. The first-ever connect never triggers this.
  void _onStatus(MatchmakerRealtimeStatus status) {
    if (isClosed) return;
    final shouldCatchUp =
        _hasBeenConnected && status == MatchmakerRealtimeStatus.connected;
    if (status == MatchmakerRealtimeStatus.connected) {
      _hasBeenConnected = true;
    }
    if (shouldCatchUp) refresh();
  }

  /// Newest-first by `lastMessageAt`; rows with a null timestamp sort last.
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
    await super.close();
  }
}

class _ColleagueConversationsFetchException implements Exception {
  const _ColleagueConversationsFetchException(this.message);
  final String message;
  @override
  String toString() => message;
}
