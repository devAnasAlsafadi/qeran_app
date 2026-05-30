import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/matchmaker_dashboard_stats.dart';

/// Wire model for `GET /api/matchmaker/dashboard` → `data`.
///
/// Exact shape (backend v2 doc §4):
/// ```json
/// {
///   "pendingUsersCount": 5,
///   "approvedSubscribedCount": 12,
///   "approvedUnsubscribedCount": 8,
///   "activeCompatibilityCasesCount": 3,
///   "unreadMessagesCount": 7,
///   "totalAssignedUsers": 25
/// }
/// ```
class MatchmakerDashboardModel {
  final int pendingUsersCount;
  final int approvedSubscribedCount;
  final int approvedUnsubscribedCount;
  final int activeCompatibilityCasesCount;
  final int unreadMessagesCount;
  final int totalAssignedUsers;

  const MatchmakerDashboardModel({
    required this.pendingUsersCount,
    required this.approvedSubscribedCount,
    required this.approvedUnsubscribedCount,
    required this.activeCompatibilityCasesCount,
    required this.unreadMessagesCount,
    required this.totalAssignedUsers,
  });

  factory MatchmakerDashboardModel.fromJson(Map<String, dynamic> json) =>
      MatchmakerDashboardModel(
        pendingUsersCount: parseInt(json['pendingUsersCount']),
        approvedSubscribedCount: parseInt(json['approvedSubscribedCount']),
        approvedUnsubscribedCount: parseInt(json['approvedUnsubscribedCount']),
        activeCompatibilityCasesCount:
            parseInt(json['activeCompatibilityCasesCount']),
        unreadMessagesCount: parseInt(json['unreadMessagesCount']),
        totalAssignedUsers: parseInt(json['totalAssignedUsers']),
      );

  MatchmakerDashboardStats toEntity() => MatchmakerDashboardStats(
        pendingUsersCount: pendingUsersCount,
        approvedSubscribedCount: approvedSubscribedCount,
        approvedUnsubscribedCount: approvedUnsubscribedCount,
        activeCompatibilityCasesCount: activeCompatibilityCasesCount,
        unreadMessagesCount: unreadMessagesCount,
        totalAssignedUsers: totalAssignedUsers,
      );
}
