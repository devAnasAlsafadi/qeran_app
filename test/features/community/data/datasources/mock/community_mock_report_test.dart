import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/data/datasources/mock/community_mock_datasource.dart';
import 'package:qeran/features/report/domain/entities/report_reason.dart';
import 'package:qeran/features/report/domain/entities/report_target.dart';

import '../../../fixtures/community_mock_harness.dart';

/// Reports stay in the mock's memory (Q3), answered as the server does
/// (§5.1).
void main() {
  late CommunityMockDataSource ds;

  setUp(() => ds = seededMock());

  Future<void> report(ReportContentKind kind, int id) => ds.reportContent(
    ContentReportTarget(kind, id),
    reason: ReportReason.spam,
  );

  Future<int> firstPost() async =>
      (await ds.getFeed(page: 1, pageSize: 20)).items.first.id;

  test(
    'a post and someone\'s comment are recorded; a repeat is fine',
    () async {
      final post = await firstPost();
      final mine = await ds.createComment(post, 'سؤال');
      final someone = (await ds.getComments(
        post,
        page: 1,
        pageSize: 20,
      )).items.firstWhere((c) => c.id != mine.id);

      await report(ReportContentKind.post, post);
      await report(ReportContentKind.comment, someone.id);
      await report(ReportContentKind.comment, someone.id);

      expect(ds.store.reports, [
        ContentReportTarget(ReportContentKind.post, post),
        ContentReportTarget(ReportContentKind.comment, someone.id),
        ContentReportTarget(ReportContentKind.comment, someone.id),
      ]);
    },
  );

  test('gone content is TARGET_CONTENT_NOT_FOUND', () async {
    await expectLater(
      report(ReportContentKind.post, 999999),
      throwsCoded('TARGET_CONTENT_NOT_FOUND'),
    );
    await expectLater(
      report(ReportContentKind.reply, 999999),
      throwsCoded('TARGET_CONTENT_NOT_FOUND'),
    );
  });

  test('one\'s own comment is VALIDATION_ERROR', () async {
    final mine = await ds.createComment(await firstPost(), 'سؤال');

    await expectLater(
      report(ReportContentKind.comment, mine.id),
      throwsCoded('VALIDATION_ERROR'),
    );
    expect(ds.store.reports, isEmpty);
  });
}
