import 'package:qeran/features/community/domain/entities/community_author.dart';
import 'package:qeran/features/community/domain/entities/community_comment.dart';
import 'package:qeran/features/community/domain/entities/community_page.dart';

import 'community_post_fixtures.dart';

/// Comments and replies for widget and cubit tests, with the board's people.

const sara = CommunityAuthor(
  id: 'member-1',
  displayName: 'سارة',
  isMatchmaker: false,
);

const fahad = CommunityAuthor(
  id: 'member-2',
  displayName: 'فهد',
  isMatchmaker: false,
);

const saraText = 'جزاكِ الله خيراً، كنت أظن أن الاستخارة لا تتم إلا برؤيا.';
const fahadText = 'Very helpful, thank you for sharing.';
const hudaReply = 'وإياكِ. الرؤيا ليست شرطاً، والمهم أن تمضي في الأسباب.';

/// A top-level comment on post 1 — or, with [parentId], a reply.
CommunityComment testComment({
  int id = 10,
  int postId = 1,
  int? parentId,
  CommunityAuthor author = sara,
  String text = saraText,
  int likeCount = 0,
  bool likedByMe = false,
  int replyCount = 0,
  DateTime? createdAt,
  bool isMine = false,
  bool canDelete = false,
  bool? canBlock,
}) => CommunityComment(
  id: id,
  postId: postId,
  parentCommentId: parentId,
  author: author,
  text: text,
  likeCount: likeCount,
  likedByMe: likedByMe,
  replyCount: replyCount,
  createdAt: createdAt,
  isMine: isMine,
  canDelete: canDelete,
  canBlock: canBlock ?? (!author.isMatchmaker && !isMine),
);

/// [id], a reply under comment [parentId] — Huda's, unless told otherwise.
CommunityComment testReply({
  int id = 100,
  int parentId = 10,
  CommunityAuthor author = huda,
  String text = hudaReply,
  int likeCount = 0,
  bool likedByMe = false,
}) => testComment(
  id: id,
  parentId: parentId,
  author: author,
  text: text,
  likeCount: likeCount,
  likedByMe: likedByMe,
);

/// Comments [from]..[to], newest first.
List<CommunityComment> comments(int from, int to) => [
  for (var id = from; id <= to; id++) testComment(id: id),
];

/// One page of [items]: page [page] of [totalPages], [totalCount] in all.
CommunityPage<CommunityComment> commentPage(
  List<CommunityComment> items, {
  int page = 1,
  int totalPages = 1,
  int? totalCount,
}) => CommunityPage(
  items: items,
  pageNumber: page,
  pageSize: 20,
  totalCount: totalCount ?? items.length,
  totalPages: totalPages,
);
