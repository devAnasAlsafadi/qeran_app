import 'package:equatable/equatable.dart';

import 'matchmaker_card_answer.dart';

/// A single row in any of the three matchmaker user lists. The common
/// fields ([userId], [fullName], [profileImageUrl], [assignedAt], [age],
/// [answers]) are present on every list ([age] is `null` when the user has
/// no Date answer; [answers] is `const []`, never null, when none are
/// flagged); the per-list extras are nullable and only set for the list
/// that carries them:
///   • [hasProfileImage]        → pending only
///   • [chatConversationId]     → approved-unsubscribed + approved-subscribed
///   • [subscriptionPlanId]     → approved-subscribed only
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
  final int? age;
  final List<MatchmakerCardAnswer> answers;

  final bool? hasProfileImage;
  final int? chatConversationId;

  /// Stable plan key for cross-locale plan matching — pair against
  /// `SubscriptionPlan.planId`, NOT the displayed [subscriptionPlanName].
  final int? subscriptionPlanId;
  final String? subscriptionPlanName;
  final DateTime? subscriptionExpiresAt;

  const MatchmakerUserRow({
    required this.userId,
    required this.fullName,
    required this.profileImageUrl,
    required this.assignedAt,
    this.age,
    this.answers = const [],
    this.hasProfileImage,
    this.chatConversationId,
    this.subscriptionPlanId,
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
        age,
        answers,
        hasProfileImage,
        chatConversationId,
        subscriptionPlanId,
        subscriptionPlanName,
        subscriptionExpiresAt,
      ];
}
