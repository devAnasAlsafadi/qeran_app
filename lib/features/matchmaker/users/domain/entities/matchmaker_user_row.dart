import 'package:equatable/equatable.dart';

/// A single row in any of the three matchmaker user lists. Common fields
/// are always present; the per-list extras are nullable and only set for
/// the list that carries them:
///   • [chatConversationId]     → approved-unsubscribed + approved-subscribed
///   • [subscriptionPlanName]   → approved-subscribed only
///   • [subscriptionExpiresAt]  → approved-subscribed only
///
/// [profileImageUrl] is already absolute (the data layer runs the
/// server's relative path through `EndPoints.absoluteUrl`); `null` when
/// the user has no profile image.
class MatchmakerUserRow extends Equatable {
  final String userId;
  final String name;
  final String gender;
  final int? age;
  final bool hasProfileImage;
  final String? profileImageUrl;
  final DateTime? questionsCompletedAt;

  final int? chatConversationId;
  final String? subscriptionPlanName;
  final DateTime? subscriptionExpiresAt;

  const MatchmakerUserRow({
    required this.userId,
    required this.name,
    required this.gender,
    required this.age,
    required this.hasProfileImage,
    required this.profileImageUrl,
    required this.questionsCompletedAt,
    this.chatConversationId,
    this.subscriptionPlanName,
    this.subscriptionExpiresAt,
  });

  bool get isSubscribed =>
      subscriptionPlanName != null && subscriptionPlanName!.isNotEmpty;

  @override
  List<Object?> get props => [
        userId,
        name,
        gender,
        age,
        hasProfileImage,
        profileImageUrl,
        questionsCompletedAt,
        chatConversationId,
        subscriptionPlanName,
        subscriptionExpiresAt,
      ];
}
