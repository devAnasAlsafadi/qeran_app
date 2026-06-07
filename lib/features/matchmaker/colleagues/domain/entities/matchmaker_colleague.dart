import 'package:equatable/equatable.dart';

/// One row of the colleague directory (`GET /api/matchmaker/colleagues`) — the
/// list a matchmaker browses to START a chat with another matchmaker.
/// [profileImageUrl] is already absolute (the data layer runs the server's
/// relative path through `EndPoints.absoluteUrl`); `null` when absent.
///
/// [conversationId] is `null` until a chat has been opened with this colleague;
/// the "start chat" action resolves it via `colleagues/{id}/open-chat`.
class MatchmakerColleague extends Equatable {
  final String matchmakerId;
  final String name;
  final String? profileImageUrl;
  final int? conversationId;

  const MatchmakerColleague({
    required this.matchmakerId,
    required this.name,
    required this.profileImageUrl,
    required this.conversationId,
  });

  /// True when a conversation already exists with this colleague.
  bool get hasConversation => conversationId != null;

  @override
  List<Object?> get props => [
        matchmakerId,
        name,
        profileImageUrl,
        conversationId,
      ];
}
