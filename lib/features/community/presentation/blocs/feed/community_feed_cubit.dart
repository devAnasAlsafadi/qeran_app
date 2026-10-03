import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/errors.dart';
import '../../../../../core/state/safe_emit.dart';
import '../../../domain/entities/community_like_state.dart';
import '../../../domain/entities/community_page.dart';
import '../../../domain/entities/community_post.dart';
import '../../../domain/entities/community_post_change.dart';
import '../../../domain/usecases/get_community_feed_usecase.dart';
import '../../../domain/usecases/set_post_like_usecase.dart';
import '../../../domain/usecases/watch_community_post_changes_usecase.dart';
import '../likes.dart';
import 'community_feed_state.dart';
import 'feed_posts.dart';

/// The Community feed (B1–B13): pages newest first with each post once, a
/// pull to refresh that keeps the posts until the new page lands, the next
/// page with its own retry, and the optimistic like. Changes made elsewhere
/// (a like or a comment on the post screen, a post gone) arrive on the
/// repository's stream and patch the list.
class CommunityFeedCubit extends Cubit<CommunityFeedState>
    with SafeEmit<CommunityFeedState> {
  CommunityFeedCubit({
    required GetCommunityFeedUseCase getFeed,
    required SetPostLikeUseCase setPostLike,
    required WatchCommunityPostChangesUseCase watchChanges,
  }) : _getFeed = getFeed,
       _setPostLike = setPostLike,
       super(const CommunityFeedState()) {
    _changes = watchChanges().listen(_onChange);
  }

  final GetCommunityFeedUseCase _getFeed;
  final SetPostLikeUseCase _setPostLike;
  late final StreamSubscription<CommunityPostChange> _changes;

  /// Posts whose like is on its way: a second tap waits for the answer.
  final Set<int> _liking = {};

  /// The first page — on opening, and from the error state's retry (B5).
  Future<void> load() async {
    if (state.status == CommunityFeedStatus.loading) return;
    emit(state.copyWith(status: CommunityFeedStatus.loading));
    final result = await _getFeed(page: 1);
    result.fold(
      (_) => emit(state.copyWith(status: CommunityFeedStatus.failure)),
      (page) => emit(_firstPage(page)),
    );
  }

  /// Pull to refresh (B7). Offline or failing, the posts stay (B6).
  Future<void> refresh() async {
    if (!_settled) return load();
    if (state.refreshing) return;
    emit(state.copyWith(refreshing: true));
    final result = await _getFeed(page: 1);
    result.fold(
      (_) => emit(state.copyWith(refreshing: false)),
      (page) => emit(_firstPage(page)),
    );
  }

  /// The next page, as the member nears the end (B8).
  Future<void> loadMore() async {
    final s = state;
    final ready = s.status == CommunityFeedStatus.loaded && s.hasMore;
    if (!ready || s.loadingMore || s.pageFailed || s.refreshing) return;
    emit(s.copyWith(loadingMore: true));
    final result = await _getFeed(page: s.page + 1);
    result.fold(
      (_) => emit(state.copyWith(loadingMore: false, pageFailed: true)),
      (page) => emit(
        state.copyWith(
          posts: appendNewPosts(state.posts, page.items),
          page: page.pageNumber,
          hasMore: page.hasMore,
          loadingMore: false,
        ),
      ),
    );
  }

  /// The page error's retry (B9).
  Future<void> retryPage() {
    emit(state.copyWith(pageFailed: false));
    return loadMore();
  }

  /// Like or unlike [postId] at once, then settle on the server's answer;
  /// on failure, take it back and say so (B13). A [readOnly] member is told
  /// why instead (B12) — and so is one the server turns away.
  Future<void> toggleLike(int postId, {bool readOnly = false}) async {
    if (readOnly) return emit(state.withEvent(CommunityFeedEvent.readOnlyLike));
    final before = _post(postId);
    if (before == null || !_liking.add(postId)) return;
    final optimistic = flippedLike(before);
    emit(state.copyWith(posts: withLike(state.posts, postId, optimistic)));
    final result = await _setPostLike(postId, liked: optimistic.likedByMe);
    _liking.remove(postId);
    result.fold(
      (failure) => emit(
        state
            .copyWith(posts: _restoreLike(postId, before))
            .withEvent(_likeFailureEvent(failure)),
      ),
      (like) =>
          emit(state.copyWith(posts: withLike(state.posts, postId, like))),
    );
  }

  bool get _settled =>
      state.status == CommunityFeedStatus.loaded ||
      state.status == CommunityFeedStatus.empty;

  CommunityFeedState _firstPage(CommunityPage<CommunityPost> page) {
    final posts = distinctPosts(page.items);
    return state.copyWith(
      status: posts.isEmpty
          ? CommunityFeedStatus.empty
          : CommunityFeedStatus.loaded,
      posts: posts,
      page: page.pageNumber,
      hasMore: page.hasMore,
      loadingMore: false,
      pageFailed: false,
      refreshing: false,
    );
  }

  CommunityPost? _post(int postId) =>
      state.posts.where((post) => post.id == postId).firstOrNull;

  /// [postId]'s like back as it was before the tap.
  List<CommunityPost> _restoreLike(int postId, CommunityPost before) =>
      withLike(
        state.posts,
        postId,
        CommunityLikeState(
          likeCount: before.likeCount,
          likedByMe: before.likedByMe,
        ),
      );

  static CommunityFeedEvent _likeFailureEvent(Failure failure) =>
      isNotApprovedFailure(failure)
      ? CommunityFeedEvent.readOnlyLike
      : CommunityFeedEvent.likeFailed;

  void _onChange(CommunityPostChange change) {
    final posts = switch (change) {
      CommunityPostUpdated(:final post) => replacePost(state.posts, post),
      CommunityPostLikeChanged(:final postId, :final like) =>
        _liking.contains(postId) ? null : withLike(state.posts, postId, like),
      CommunityPostGone(:final postId) => withoutPost(state.posts, postId),
    };
    if (posts == null) return;
    final emptied = posts.isEmpty && state.status == CommunityFeedStatus.loaded;
    emit(
      state.copyWith(
        posts: posts,
        status: emptied ? CommunityFeedStatus.empty : null,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
