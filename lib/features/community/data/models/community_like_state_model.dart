import '../../domain/entities/community_like_state.dart';
import '../json_parsers.dart';

/// Wire model for a like / unlike answer (contract §3.3, §3.4):
/// `{ likeCount, likedByMe }`.
class CommunityLikeStateModel {
  final int likeCount;
  final bool likedByMe;

  const CommunityLikeStateModel({
    required this.likeCount,
    required this.likedByMe,
  });

  factory CommunityLikeStateModel.fromJson(Map<String, dynamic> json) =>
      CommunityLikeStateModel(
        likeCount: parseInt(json['likeCount']),
        likedByMe: parseBool(json['likedByMe']),
      );

  CommunityLikeState toEntity() =>
      CommunityLikeState(likeCount: likeCount, likedByMe: likedByMe);
}
