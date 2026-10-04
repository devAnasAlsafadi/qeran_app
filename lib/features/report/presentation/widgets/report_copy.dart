import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/report_reason.dart';
import '../../domain/entities/report_target.dart';

/// The sheet's title for [target]: «إبلاغ» for a profile, or what is being
/// reported (E5).
String reportTitleKey(ReportTarget target) => switch (target) {
  UserReportTarget() => LocaleKeys.report_title,
  ContentReportTarget(kind: ReportContentKind.post) =>
    LocaleKeys.report_title_post,
  ContentReportTarget(kind: ReportContentKind.comment) =>
    LocaleKeys.report_title_comment,
  ContentReportTarget(kind: ReportContentKind.reply) =>
    LocaleKeys.report_title_reply,
};

/// A reason's label. Harassment and Other read differently on content
/// («إساءة أو تنمّر», «سبب آخر») than on a profile (contract §5.1).
String reportReasonKey(ReportReason reason, ReportTarget target) {
  final content = target is ContentReportTarget;
  return switch (reason) {
    ReportReason.harassment when content =>
      LocaleKeys.report_reason_harassment_content,
    ReportReason.other when content => LocaleKeys.report_reason_other_content,
    ReportReason.inappropriateContent => LocaleKeys.report_reason_inappropriate,
    ReportReason.impersonation => LocaleKeys.report_reason_impersonation,
    ReportReason.harassment => LocaleKeys.report_reason_harassment,
    ReportReason.scam => LocaleKeys.report_reason_scam,
    ReportReason.falseInformation =>
      LocaleKeys.report_reason_false_information,
    ReportReason.contactDetails => LocaleKeys.report_reason_contact_details,
    ReportReason.spam => LocaleKeys.report_reason_spam,
    ReportReason.other => LocaleKeys.report_reason_other,
  };
}
