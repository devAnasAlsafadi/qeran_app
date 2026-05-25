import 'package:equatable/equatable.dart';

/// Bootstrap payload from `GET /api/chat/my-matchmaker`.
///
/// The single carry-over from the response we actually need: the
/// matchmaker's identity for the header and the conversation id we
/// route every other call through.
class MatchmakerInfo extends Equatable {
  final String matchmakerId;
  final String name;
  final String? profileImageUrl;
  final int conversationId;

  const MatchmakerInfo({
    required this.matchmakerId,
    required this.name,
    required this.profileImageUrl,
    required this.conversationId,
  });

  @override
  List<Object?> get props =>
      [matchmakerId, name, profileImageUrl, conversationId];
}
