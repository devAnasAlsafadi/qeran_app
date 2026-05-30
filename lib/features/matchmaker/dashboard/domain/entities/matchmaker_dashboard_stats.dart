import 'package:equatable/equatable.dart';

/// Quick-stat counters for the matchmaker dashboard, from
/// `GET /api/matchmaker/dashboard`. All counts are non-negative and
/// default to 0 when the wire field is missing or malformed.
class MatchmakerDashboardStats extends Equatable {
  final int pendingUsersCount;
  final int approvedSubscribedCount;
  final int approvedUnsubscribedCount;
  final int activeCompatibilityCasesCount;
  final int unreadMessagesCount;
  final int totalAssignedUsers;

  const MatchmakerDashboardStats({
    required this.pendingUsersCount,
    required this.approvedSubscribedCount,
    required this.approvedUnsubscribedCount,
    required this.activeCompatibilityCasesCount,
    required this.unreadMessagesCount,
    required this.totalAssignedUsers,
  });

  @override
  List<Object?> get props => [
        pendingUsersCount,
        approvedSubscribedCount,
        approvedUnsubscribedCount,
        activeCompatibilityCasesCount,
        unreadMessagesCount,
        totalAssignedUsers,
      ];
}
