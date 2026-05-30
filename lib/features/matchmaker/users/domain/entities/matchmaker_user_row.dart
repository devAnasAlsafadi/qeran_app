import 'package:equatable/equatable.dart';

/// A single row in any of the three matchmaker user lists. The common
/// fields ([userId], [fullName], [profileImageUrl], [assignedAt]) are
/// present on every list; the per-list extras are nullable and only set
/// for the list that carries them:
///   • [hasProfileImage]        → pending only
///   • [chatConversationId]     → approved-unsubscribed + approved-subscribed
///   • [subscriptionPlanName]   → approved-subscribed only
///   • [subscriptionExpiresAt]  → approved-subscribed only
///
/// [profileImageUrl] is already absolute (the data layer runs the
/// server's relative path through `EndPoints.absoluteUrl`); `null` when
/// the user has no profile image.
class MatchmakerUserRow extends Equatable {
  final String userId;
  final String fullName;
  final String? profileImageUrl;
  final DateTime? assignedAt;

  final bool? hasProfileImage;
  final int? chatConversationId;
  final String? subscriptionPlanName;
  final DateTime? subscriptionExpiresAt;

  const MatchmakerUserRow({
    required this.userId,
    required this.fullName,
    required this.profileImageUrl,
    required this.assignedAt,
    this.hasProfileImage,
    this.chatConversationId,
    this.subscriptionPlanName,
    this.subscriptionExpiresAt,
  });

  bool get isSubscribed =>
      subscriptionPlanName != null && subscriptionPlanName!.isNotEmpty;

  @override
  List<Object?> get props => [
        userId,
        fullName,
        profileImageUrl,
        assignedAt,
        hasProfileImage,
        chatConversationId,
        subscriptionPlanName,
        subscriptionExpiresAt,
      ];
}
