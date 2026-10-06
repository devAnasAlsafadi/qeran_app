import 'package:qeran/features/report/domain/entities/report_reason.dart';

import '../../domain/entities/community_flag.dart';
import '../json_parsers.dart';

/// Wire model for a flag (contract §5.3):
/// `{ id, reportCount, reasons: [{ reason, count }], lastReportedAt }`, with
/// `reasons` sorted by the server, so only the first is read.
class CommunityFlagModel {
  final int id;
  final int reportCount;
  final ReportReason? topReason;
  final DateTime? lastReportedAt;

  const CommunityFlagModel({
    required this.id,
    required this.reportCount,
    required this.topReason,
    required this.lastReportedAt,
  });

  factory CommunityFlagModel.fromJson(Map<String, dynamic> json) {
    final reasons = parseMapList(json['reasons']);
    return CommunityFlagModel(
      id: parseInt(json['id']),
      reportCount: parseInt(json['reportCount']),
      topReason: reasons.isEmpty ? null : _contentReason(reasons.first),
      lastReportedAt: parseNullableDateTime(json['lastReportedAt']),
    );
  }

  /// [entry]'s reason when it's one of the content reasons (D30), matched as
  /// the server does, ignoring case; null for one this build doesn't know.
  static ReportReason? _contentReason(Map<String, dynamic> entry) {
    final raw = parseNullableString(entry['reason'])?.trim().toLowerCase();
    for (final reason in ReportReason.content) {
      if (reason.apiValue.toLowerCase() == raw) return reason;
    }
    return null;
  }

  /// The flag in [raw], or null when there's none — every member's case.
  static CommunityFlagModel? parse(Object? raw) {
    final map = parseNullableMap(raw);
    return map == null ? null : CommunityFlagModel.fromJson(map);
  }

  CommunityFlag toEntity() => CommunityFlag(
    id: id,
    reportCount: reportCount,
    topReason: topReason,
    lastReportedAt: lastReportedAt,
  );
}
