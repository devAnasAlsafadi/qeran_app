import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/enum/gender.dart';
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

  /// Server-side recipient gender filter.
  ///
  /// ⚠️ NOT wired to any control yet, and deliberately so. The picker reads
  /// `GET /api/matchmaker/users/approved-{unsubscribed,subscribed}`, which
  /// neither accepts `?gender=` nor returns a `gender` field on the row — so a
  /// visible filter would silently do nothing, and a client-side fallback is
  /// impossible with no gender to filter on. `/matchmaker/explore` does
  /// support it, but the picker cannot use explore: recipients must be the
  /// matchmaker's OWN users. The path is threaded end-to-end so adding the
  /// control is a UI-only change once the backend accepts the param.
  Gender? _gender;

  /// Re-runs the picker from page 1 under a new gender filter.
  Future<void> setGender(Gender? gender) {
    if (_gender == gender) return Future.value();
    _gender = gender;
    return loadFirst();
  }

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
      gender: _gender,
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
        // Source exhausted with another still queued → pull it NOW rather than
        // waiting for a scroll. `loadMore` only fires from the sheet's scroll
        // listener, so a short first source (e.g. 6 unsubscribed users) never
        // scrolls and the SUBSCRIBED users were never fetched at all — the
        // picker silently listed a subset of the matchmaker's users.
        // Guarded on !morePages so this only ever BRIDGES sources; it never
        // eagerly paginates a source that still has pages of its own.
        final bridging = !morePages && moreSources;
        emit(state.copyWith(
          // Stay in the initial-load state while bridging on a still-empty
          // list, so an empty first source shows the loader rather than
          // flashing "no recipients" before the next source arrives.
          loading: bridging && items.isEmpty,
          // Keep the in-flight flag up across the bridge so a concurrent
          // scroll-driven loadMore is rejected by its own guard instead of
          // re-fetching the page we are already pulling.
          loadingMore: bridging && items.isNotEmpty,
          recipients: items,
          hasMore: hasMore,
          clearError: true,
        ));
        if (bridging) _fetchNext();
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
