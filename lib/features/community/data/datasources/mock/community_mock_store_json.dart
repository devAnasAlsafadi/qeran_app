part of 'community_mock_store.dart';

/// The store's rows in the server's JSON shapes (contract §2), with the
/// per-viewer counts and flags, and a page of them.
extension _Json on CommunityMockStore {
  Map<String, dynamic> _postJson(MockPost p) => {
    'id': p.id,
    'author': p.author,
    'text': p.text,
    'media': p.media,
    'likeCount': p.likeCount,
    'likedByMe': p.likedByMe,
    'commentCount': _comments.where((c) => c.postId == p.id).length,
    'createdAt': p.publishedAt.toUtc().toIso8601String(),
    'canDelete': p.authorId == viewer.id,
    'status': 'Published',
  };

  Map<String, dynamic> _commentJson(MockComment c) => {
    'id': c.id,
    'postId': c.postId,
    'parentCommentId': c.parentId,
    'author': c.author,
    'text': c.text,
    'likeCount': c.likeCount,
    'likedByMe': c.likedByMe,
    'replyCount': c.parentId == null ? _repliesOf(c.id).length : 0,
    'createdAt': c.createdAt.toUtc().toIso8601String(),
    'isMine': c.authorId == viewer.id,
    'canDelete': _canDelete(c),
    // D18 (a matchmaker can't be blocked) and D40 (a matchmaker can't
    // block), and never oneself.
    'canBlock':
        !viewer.isMatchmaker &&
        !c.authorIsMatchmaker &&
        c.authorId != viewer.id,
    'flag': null,
  };

  Map<String, dynamic> _paged(
    List<Map<String, dynamic>> all,
    int page,
    int pageSize,
  ) {
    final start = (page - 1) * pageSize;
    final items = (start < 0 || start >= all.length)
        ? const <Map<String, dynamic>>[]
        : all.sublist(start, math.min(start + pageSize, all.length));
    return {
      'data': items,
      'pageNumber': page,
      'pageSize': pageSize,
      'totalCount': all.length,
      'totalPages': (all.length / pageSize).ceil(),
    };
  }
}
