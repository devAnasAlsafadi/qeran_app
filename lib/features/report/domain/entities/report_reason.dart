import 'report_target.dart';

/// Report reasons — [apiValue] mirrors the backend `reason` enum exactly
/// (matched case-insensitively server-side). Sent to `POST /api/reports`.
/// A profile offers six; Community content five, two of them its own
/// ([contactDetails], [spam]) — D30.
enum ReportReason {
  inappropriateContent('InappropriateContent'),
  impersonation('Impersonation'),
  harassment('Harassment'),
  scam('Scam'),
  falseInformation('FalseInformation'),
  contactDetails('ContactDetails'),
  spam('Spam'),
  other('Other');

  final String apiValue;
  const ReportReason(this.apiValue);

  /// The reasons a report on [target] offers, in the sheet's order.
  static List<ReportReason> forTarget(ReportTarget target) => switch (target) {
    UserReportTarget() => const [
      inappropriateContent,
      impersonation,
      harassment,
      scam,
      falseInformation,
      other,
    ],
    ContentReportTarget() => const [
      harassment,
      inappropriateContent,
      contactDetails,
      spam,
      other,
    ],
  };
}
