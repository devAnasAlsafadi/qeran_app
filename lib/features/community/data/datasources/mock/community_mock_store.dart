import 'dart:math' as math;

import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../error_codes.dart';
import 'community_mock_records.dart';
import 'community_mock_seed.dart';

part 'community_mock_store_json.dart';

/// Throws what `HttpConsumer` throws for an enveloped error with [errorCode]
/// and the envelope's [data].
Never throwCommunityMockError(String errorCode, {Object? data}) =>
    throw CodedServerException(
      message: LocaleKeys.errors_generic,
      errorCode: errorCode,
      data: data,
    );

/// The mock's data, answered in the server's shapes and orders: the feed by
/// publish time, comments newest first, replies oldest first; counts and the
/// `isMine` / `canDelete` / `canBlock` flags computed for [viewer]; likes
/// idempotent; deleting a comment deletes its replies (D16).
class CommunityMockStore {
  final CommunityMockViewer viewer;
  final DateTime Function() now;
  final List<MockPost> _posts;
  final List<MockComment> _comments;
  int _nextCommentId = 9000;

  CommunityMockStore({
    required this.viewer,
    required this.now,
    required CommunityMockSeed seed,
  })  : _posts = [...seed.posts],
        _comments = [...seed.comments];

  Map<String, dynamic> feedPage(int page, int pageSize) {
    final posts = [..._posts]
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return _paged(posts.map(_postJson).toList(), page, pageSize);
  }

  Map<String, dynamic> post(int postId) => _postJson(requirePost(postId));

  Map<String, dynamic> setPostLike(int postId, {required bool liked}) {
    final p = requirePost(postId);
    if (p.likedByMe != liked) {
      p.likeCount += liked ? 1 : -1;
      p.likedByMe = liked;
    }
    return {'likeCount': p.likeCount, 'likedByMe': p.likedByMe};
  }

  Map<String, dynamic> setCommentLike(int commentId, {required bool liked}) {
    final c = requireComment(commentId);
    if (c.likedByMe != liked) {
      c.likeCount += liked ? 1 : -1;
      c.likedByMe = liked;
    }
    return {'likeCount': c.likeCount, 'likedByMe': c.likedByMe};
  }

  Map<String, dynamic> commentsPage(int postId, int page, int pageSize) {
    requirePost(postId);
    final top = _comments
        .where((c) => c.postId == postId && c.parentId == null)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _paged(top.map(_commentJson).toList(), page, pageSize);
  }

  Map<String, dynamic> repliesPage(int commentId, int page, int pageSize) {
    requireComment(commentId);
    return _paged(_repliesOf(commentId).map(_commentJson).toList(), page,
        pageSize);
  }

  Map<String, dynamic> comment(int commentId) =>
      _commentJson(requireComment(commentId));

  /// Adds a comment (or, with [parentId], a reply) by the viewer. Gates and
  /// validation are the datasource's; this only stores it.
  Map<String, dynamic> addComment({
    required int postId,
    int? parentId,
    required String text,
  }) {
    final c = MockComment(
      id: _nextCommentId++,
      postId: postId,
      parentId: parentId,
      author: viewer.toAuthorJson(),
      text: text,
      createdAt: now(),
    );
    _comments.add(c);
    return _commentJson(c);
  }

  void deleteComment(int commentId) {
    final c = requireComment(commentId);
    if (!_canDelete(c)) {
      throwCommunityMockError(CommunityErrorCodes.unauthorized);
    }
    _comments.removeWhere((x) => x.id == commentId || x.parentId == commentId);
  }

  MockPost requirePost(int postId) =>
      _posts.where((p) => p.id == postId).firstOrNull ??
      throwCommunityMockError(CommunityErrorCodes.postNotFound);

  MockComment requireComment(int commentId) =>
      _comments.where((c) => c.id == commentId).firstOrNull ??
      throwCommunityMockError(CommunityErrorCodes.commentNotFound);

  List<MockComment> _repliesOf(int commentId) => _comments
      .where((c) => c.parentId == commentId)
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  bool _canDelete(MockComment c) =>
      c.authorId == viewer.id || requirePost(c.postId).authorId == viewer.id;
}
