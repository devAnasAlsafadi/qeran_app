import 'package:equatable/equatable.dart';

/// What a report is about (contract §5.1): a member's profile, or a piece of
/// Community content — a post, a comment or a reply. The sheet's title and
/// its reasons follow it (D30).
sealed class ReportTarget extends Equatable {
  const ReportTarget();
}

final class UserReportTarget extends ReportTarget {
  const UserReportTarget(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

enum ReportContentKind { post, comment, reply }

final class ContentReportTarget extends ReportTarget {
  const ContentReportTarget(this.kind, this.id);

  final ReportContentKind kind;
  final int id;

  /// The server's `targetContentType`: a reply is a `Comment` (§2.4).
  String get apiType => kind == ReportContentKind.post ? 'Post' : 'Comment';

  @override
  List<Object?> get props => [kind, id];
}
