import 'package:equatable/equatable.dart';

import 'community_comment.dart';
import 'community_flag.dart';

/// A row of «البلاغات» (contract §5.3): an open flag, the comment or reply it
/// is on, and the post that holds it — its id and the start of its text.
class CommunityFlaggedItem extends Equatable {
  final CommunityFlag flag;
  final CommunityComment comment;
  final int postId;

  /// The server's one-line start of the post's text, for «على: …».
  final String postSnippet;

  const CommunityFlaggedItem({
    required this.flag,
    required this.comment,
    required this.postId,
    required this.postSnippet,
  });

  @override
  List<Object?> get props => [flag, comment, postId, postSnippet];
}
