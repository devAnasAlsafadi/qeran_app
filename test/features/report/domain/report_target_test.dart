import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/report/domain/entities/report_reason.dart';
import 'package:qeran/features/report/domain/entities/report_target.dart';

/// D30: one sheet, whose reasons follow what is reported.
void main() {
  test('a profile keeps its six reasons', () {
    expect(ReportReason.forTarget(const UserReportTarget('u-1')), [
      ReportReason.inappropriateContent,
      ReportReason.impersonation,
      ReportReason.harassment,
      ReportReason.scam,
      ReportReason.falseInformation,
      ReportReason.other,
    ]);
  });

  test('content offers five, in the board\'s order, for every kind', () {
    for (final kind in ReportContentKind.values) {
      expect(ReportReason.forTarget(ContentReportTarget(kind, 7)), [
        ReportReason.harassment,
        ReportReason.inappropriateContent,
        ReportReason.contactDetails,
        ReportReason.spam,
        ReportReason.other,
      ]);
    }
  });

  test('the two new reasons carry the server\'s names', () {
    expect(ReportReason.contactDetails.apiValue, 'ContactDetails');
    expect(ReportReason.spam.apiValue, 'Spam');
  });

  test('a reply is reported as a Comment (§2.4)', () {
    expect(
      const ContentReportTarget(ReportContentKind.post, 1).apiType,
      'Post',
    );
    expect(
      const ContentReportTarget(ReportContentKind.comment, 1).apiType,
      'Comment',
    );
    expect(
      const ContentReportTarget(ReportContentKind.reply, 1).apiType,
      'Comment',
    );
  });
}
