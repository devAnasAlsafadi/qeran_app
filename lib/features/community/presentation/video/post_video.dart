import '../../domain/entities/community_media.dart';
import '../../domain/entities/community_post.dart';

/// [post]'s video, when it carries one.
CommunityVideo? videoOf(CommunityPost post) => switch (post.media) {
  CommunitySingleVideo(:final video) => video,
  _ => null,
};
