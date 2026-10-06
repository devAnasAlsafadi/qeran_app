import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/errors.dart';
import '../../../../../core/state/safe_emit.dart';
import '../../../domain/entities/community_page.dart';
import '../../../domain/entities/community_post.dart';
import '../../../domain/entities/community_post_change.dart';
import '../../../domain/entities/community_media.dart';
import '../../../domain/usecases/get_community_post_usecase.dart';
import '../../../domain/usecases/set_post_like_usecase.dart';
import '../../../domain/usecases/watch_community_post_changes_usecase.dart';
import '../../video/post_video.dart';
import 'community_feed_state.dart';
import 'feed_likes.dart';
import 'feed_posts.dart';

/// A page of posts: the feed's (3.1), or her own (6.1).
typedef CommunityPostsSource =
    Future<Either<Failure, CommunityPage<CommunityPost>>> Function({
      required int page,
    });

/// The Community feed (B1–B13): pages newest first with each post once, a
/// pull to refresh that keeps the posts until the new page lands, the next
/// page with its own retry, and the optimistic like. Changes made elsewhere
/// (a like or a comment on the post screen, a post gone) arrive on the
/// repository's stream and patch the list. Her «منشوراتي» is the same list
/// over her own posts, where a new one joins in any status ([anyStatus]).
class CommunityFeedCubit extends Cubit<CommunityFeedState>
    with SafeEmit<CommunityFeedState>, FeedLikes {
  CommunityFeedCubit({
    required CommunityPostsSource getFeed,
    required GetCommunityPostUseCase getPost,
    required SetPostLikeUseCase setPostLike,
    required WatchCommunityPostChangesUseCase watchChanges,
    bool anyStatus = false,
  }) : _getFeed = getFeed,
       _getPost = getPost,
       _setPostLike = setPostLike,
       _anyStatus = anyStatus,
       super(const CommunityFeedState()) {
    _changes = watchChanges().listen(_onChange);
  }

  final CommunityPostsSource _getFeed;
  final bool _anyStatus;
  final GetCommunityPostUseCase _getPost;
  final SetPostLikeUseCase _setPostLike;

  @override
  SetPostLikeUseCase get setPostLike => _setPostLike;

  late final StreamSubscription<CommunityPostChange> _changes;

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

  void _onChange(CommunityPostChange change) {
    final posts = switch (change) {
      CommunityPostUpdated(:final post) => replacePost(state.posts, post),
      CommunityPostLikeChanged(:final postId, :final like) =>
        liking.contains(postId) ? null : withLike(state.posts, postId, like),
      CommunityPostGone(:final postId) => withoutPost(state.posts, postId),
      CommunityPostCreated(:final post) =>
        _settled
            ? withCreatedPost(state.posts, post, anyStatus: _anyStatus)
            : null,
    };
    if (posts == null) return;
    emit(state.copyWith(posts: posts, status: _statusWith(posts)));
  }

  /// Loaded ↔ empty as [posts] empties or fills; anything else unchanged.
  CommunityFeedStatus? _statusWith(List<CommunityPost> posts) =>
      switch (state.status) {
        CommunityFeedStatus.loaded when posts.isEmpty =>
          CommunityFeedStatus.empty,
        CommunityFeedStatus.empty when posts.isNotEmpty =>
          CommunityFeedStatus.loaded,
        _ => null,
      };

  /// [postId]'s video read again, for a lapsed link (S19); the card's copy
  /// is patched through the repository's stream as well.
  Future<CommunityVideo?> freshVideo(int postId) async =>
      (await _getPost(postId)).fold((_) => null, videoOf);

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
