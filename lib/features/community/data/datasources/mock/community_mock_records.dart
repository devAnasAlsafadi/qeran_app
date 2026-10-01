/// The mock's in-memory rows. Mutable on purpose — likes, deletes and new
/// comments change them — and turned into server-shaped JSON by the store,
/// so the app parses mock data with the same models as live data.
library;

/// Who the mock answers as: the signed-in member (or matchmaker), so new
/// comments get an author and every row its `isMine` / `canDelete` /
/// `canBlock` for this viewer.
class CommunityMockViewer {
  final String id;
  final String displayName;
  final bool isMatchmaker;

  const CommunityMockViewer({
    required this.id,
    required this.displayName,
    this.isMatchmaker = false,
  });

  Map<String, dynamic> toAuthorJson() => {
        'id': id,
        'displayName': displayName,
        'isMatchmaker': isMatchmaker,
        'profileImageUrl': null,
      };
}

class MockPost {
  final int id;
  final Map<String, dynamic> author;
  final String text;
  final List<Map<String, dynamic>> media;
  int likeCount;
  bool likedByMe;
  final DateTime publishedAt;

  MockPost({
    required this.id,
    required this.author,
    required this.text,
    this.media = const [],
    this.likeCount = 0,
    this.likedByMe = false,
    required this.publishedAt,
  });

  String get authorId => author['id'] as String;
}

class MockComment {
  final int id;
  final int postId;
  final int? parentId;
  final Map<String, dynamic> author;
  final String text;
  int likeCount;
  bool likedByMe;
  final DateTime createdAt;

  MockComment({
    required this.id,
    required this.postId,
    this.parentId,
    required this.author,
    required this.text,
    this.likeCount = 0,
    this.likedByMe = false,
    required this.createdAt,
  });

  String get authorId => author['id'] as String;
  bool get authorIsMatchmaker => author['isMatchmaker'] == true;
}
