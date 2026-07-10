import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/features/chat/domain/entities/share_profile_outcome.dart';
import 'package:qeran/features/chat/domain/usecases/share_profile_usecase.dart';

import '../../../../conversations/domain/usecases/open_user_chat_usecase.dart';
import '../../../../users/domain/entities/matchmaker_user_row.dart';
import '../../../../users/domain/entities/matchmaker_users_list.dart';
import '../../../../users/domain/usecases/fetch_matchmaker_users_usecase.dart';
import 'matchmaker_share_state.dart';

/// Drives the Share recipient picker for the browsed explore user [sharedUserId].
/// Aggregates the matchmaker's two APPROVED user lists (unsubscribed →
/// subscribed; pending excluded) into one infinite-scroll list and tracks the
/// multi-selection. The send orchestration lands in the next sub-step.
class MatchmakerShareCubit extends Cubit<MatchmakerShareState> with SafeEmit<MatchmakerShareState> {
  final FetchMatchmakerUsersUseCase _fetchUsers;
  final OpenUserChatUseCase _openChat;
  final ShareProfileUseCase _shareProfile;

  /// The browsed profile being shared into each recipient's conversation.
  final String sharedUserId;

  /// Recipient sources, in order — approved only, never pending.
  static const List<MatchmakerUsersList> _sources = [
    MatchmakerUsersList.approvedUnsubscribed,
    MatchmakerUsersList.approvedSubscribed,
  ];
  static const int _pageSize = 20;

  int _sourceIndex = 0;
  int _page = 1;

  MatchmakerShareCubit({
    required this.sharedUserId,
    required FetchMatchmakerUsersUseCase fetchUsers,
    required OpenUserChatUseCase openChat,
    required ShareProfileUseCase shareProfile,
  })  : _fetchUsers = fetchUsers,
        _openChat = openChat,
        _shareProfile = shareProfile,
        super(const MatchmakerShareState());

  Future<void> loadFirst() async {
    _sourceIndex = 0;
    _page = 1;
    emit(const MatchmakerShareState(loading: true));
    await _fetchNext();
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    emit(state.copyWith(loadingMore: true));
    await _fetchNext();
  }

  Future<void> _fetchNext() async {
    final result = await _fetchUsers(
      list: _sources[_sourceIndex],
      page: _page,
      pageSize: _pageSize,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        loading: false,
        loadingMore: false,
        errorMessage: failure.message,
      )),
      (page) {
        final items = [...state.recipients, ...page.items];
        final morePages = page.hasMore;
        final moreSources = _sourceIndex < _sources.length - 1;
        if (morePages) {
          _page++;
        } else if (moreSources) {
          _sourceIndex++;
          _page = 1;
        }
        final hasMore = morePages || moreSources;
        emit(state.copyWith(
          recipients: items,
          loading: false,
          loadingMore: false,
          hasMore: hasMore,
          clearError: true,
        ));
        // First source empty but another remains → pull it so the picker
        // never shows an empty list while recipients still exist.
        if (items.isEmpty && hasMore) _fetchNext();
      },
    );
  }

  void toggle(String userId) {
    final next = Set<String>.from(state.selected);
    next.contains(userId) ? next.remove(userId) : next.add(userId);
    emit(state.copyWith(selected: next));
  }

  /// Shares the browsed profile to every selected recipient, SEQUENTIALLY:
  /// resolve each recipient's conversation (reuse `chatConversationId` when the
  /// row carries it, else `OpenUserChatUseCase`), then `ShareProfileUseCase`.
  /// A 429 (`ShareProfileRateLimited`) or any failure counts as NOT shared, so
  /// the tally is honest ("N of M"). Never throws; emits a one-shot outcome.
  Future<void> send() async {
    if (state.sending) return; // in-flight guard
    final targets = state.recipients
        .where((r) => state.selected.contains(r.userId))
        .toList(growable: false);
    if (targets.isEmpty) return;

    emit(state.copyWith(sending: true));
    var shared = 0;
    for (final row in targets) {
      final conversationId = await _resolveConversation(row);
      if (conversationId == null) continue; // resolve failed → not shared
      final result = await _shareProfile(
        conversationId: conversationId,
        sharedUserId: sharedUserId,
      );
      // Only an explicit success counts; rate-limited/failure do not.
      final ok = result.fold((_) => false, (o) => o is ShareProfileSuccess);
      if (ok) shared++;
    }
    if (isClosed) return;

    final total = targets.length;
    final outcome = shared == 0
        ? ShareSendOutcome.failure
        : (shared == total
            ? ShareSendOutcome.success
            : ShareSendOutcome.partial);
    emit(state.copyWith(
      sending: false,
      outcome: outcome,
      sharedCount: shared,
      totalCount: total,
      eventVersion: state.eventVersion + 1,
    ));
  }

  /// The recipient's conversation id — the row's `chatConversationId` when
  /// present (approved lists carry it), else resolved via open-chat. Null when
  /// the resolve fails (treated as a non-share, never fatal).
  Future<int?> _resolveConversation(MatchmakerUserRow row) async {
    if (row.chatConversationId != null) return row.chatConversationId;
    final result = await _openChat(row.userId);
    return result.fold((_) => null, (id) => id);
  }
}
