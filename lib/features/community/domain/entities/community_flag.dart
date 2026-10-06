import 'package:equatable/equatable.dart';
import 'package:qeran/features/report/domain/entities/report_reason.dart';

/// An open report on a comment or a reply on her post (contract §5.3): one
/// per item however many reports it collects. Only the post's author
/// receives it; she sees the reasons, never the reporters.
class CommunityFlag extends Equatable {
  final int id;
  final int reportCount;

  /// `reasons[0]`: the reason reported most, ties going to the most recent.
  /// Null when this build doesn't know it — the flag line then shows the
  /// count alone (S18).
  final ReportReason? topReason;

  /// Null only if the server sent none.
  final DateTime? lastReportedAt;

  const CommunityFlag({
    required this.id,
    required this.reportCount,
    this.topReason,
    this.lastReportedAt,
  });

  @override
  List<Object?> get props => [id, reportCount, topReason, lastReportedAt];
}
