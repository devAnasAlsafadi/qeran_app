/// Report reasons — [apiValue] mirrors the backend `reason` enum exactly
/// (matched case-insensitively server-side): InappropriateContent |
/// Impersonation | Harassment | Scam | FalseInformation | Other. Sent to
/// `POST /api/reports`.
enum ReportReason {
  inappropriateContent('InappropriateContent'),
  impersonation('Impersonation'),
  harassment('Harassment'),
  scam('Scam'),
  falseInformation('FalseInformation'),
  other('Other');

  final String apiValue;
  const ReportReason(this.apiValue);
}
