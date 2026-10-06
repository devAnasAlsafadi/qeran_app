import 'package:equatable/equatable.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';

/// The `CommunityPostStatusChanged` hub event (contract §6): one of her
/// posts left `Processing` — `{ postId, status }`. Sent to the post's author
/// only.
class CommunityPostStatusChange extends Equatable {
  const CommunityPostStatusChange({required this.postId, required this.status});

  final int postId;
  final CommunityPostStatus status;

  @override
  List<Object?> get props => [postId, status];
}
