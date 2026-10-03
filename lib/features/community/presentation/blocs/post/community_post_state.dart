import 'package:equatable/equatable.dart';

import '../../../domain/entities/community_post.dart';

/// One-shot messages for the post screen, told apart by
/// [CommunityPostReady.eventVersion].
enum CommunityPostEvent {
  none,

  /// The like didn't save and was taken back.
  likeFailed,

  /// A member who can't take part yet tapped Like (D9).
  readOnlyLike,
}

/// The post at the top of its screen.
sealed class CommunityPostState extends Equatable {
  const CommunityPostState();

  @override
  List<Object?> get props => [];
}

/// Opened without a copy of the post (from a notification): on its way.
final class CommunityPostLoading extends CommunityPostState {
  const CommunityPostLoading();
}

final class CommunityPostReady extends CommunityPostState {
  final CommunityPost post;
  final CommunityPostEvent event;
  final int eventVersion;

  const CommunityPostReady(
    this.post, {
    this.event = CommunityPostEvent.none,
    this.eventVersion = 0,
  });

  /// [next] in place of the post; the last message stays told.
  CommunityPostReady withPost(CommunityPost next) =>
      CommunityPostReady(next, event: event, eventVersion: eventVersion);

  /// This state, telling the screen [next] once.
  CommunityPostReady withEvent(CommunityPostEvent next) =>
      CommunityPostReady(post, event: next, eventVersion: eventVersion + 1);

  @override
  List<Object?> get props => [post, event, eventVersion];
}

/// `POST_NOT_FOUND` — deleted, or no longer visible to this viewer (C7).
final class CommunityPostRemoved extends CommunityPostState {
  const CommunityPostRemoved();
}

/// No copy of the post, and it couldn't be read: the error with its retry.
final class CommunityPostFailed extends CommunityPostState {
  const CommunityPostFailed();
}
