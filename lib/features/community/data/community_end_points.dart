/// Community paths (`03-api-contract.md` §3–§6), relative to
/// `EndPoints.baseUrl` like every other path. Kept in the feature because
/// `core/api/end_points.dart` is past the 200-line limit.
abstract final class CommunityEndPoints {
  static const String posts = 'community/posts';
  static String post(int postId) => 'community/posts/$postId';
  static String postLike(int postId) => 'community/posts/$postId/like';
  static String postComments(int postId) => 'community/posts/$postId/comments';

  static String comment(int commentId) => 'community/comments/$commentId';
  static String commentLike(int commentId) =>
      'community/comments/$commentId/like';
  static String commentReplies(int commentId) =>
      'community/comments/$commentId/replies';

  // The post's author (contract §5.3, §6).
  static const String myPosts = 'community/my-posts';
  static const String myPostFlags = 'community/my-posts/flags';
  static String dismissFlag(int flagId) => 'community/flags/$flagId/dismiss';

  // Her media, uploaded before the post is made (contract §6.7–6.9).
  static const String mediaImages = 'community/media/images';
  static String media(String mediaId) => 'community/media/$mediaId';

  static const String config = 'community/config';
  static const String guidelines = 'community/guidelines';
  static const String acceptGuidelines = 'community/guidelines/accept';
}
