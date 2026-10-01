import 'package:equatable/equatable.dart';

/// The server's answer to a like or unlike on a post or a comment
/// (contract §3.3, §3.4). Both calls are idempotent, so the optimistic
/// state is replaced by this one, never added to.
class CommunityLikeState extends Equatable {
  final int likeCount;
  final bool likedByMe;

  const CommunityLikeState({required this.likeCount, required this.likedByMe});

  @override
  List<Object?> get props => [likeCount, likedByMe];
}
