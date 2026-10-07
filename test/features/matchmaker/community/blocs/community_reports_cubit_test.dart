import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/matchmaker/community/presentation/blocs/reports/community_reports_cubit.dart';

import '../../../community/fixtures/community_comment_fixtures.dart';
import '../reports_rig.dart';

/// «البلاغات» (E7–E10, S16, S17).
void main() {
  late ReportsHarness h;
  late CommunityReportsCubit reports;
  setUp(() {
    h = ReportsHarness();
    reports = h.newCubit();
  });
  tearDown(() => reports.close());

  List<int> flags() => [for (final i in reports.state.items) i.flag.id];

  test('loaded, none waiting (E9), or failed (E10)', () async {
    h.page(1, [reportedComment, reportedReply]);
    await reports.load();
    expect(reports.state.status, CommunityReportsStatus.loaded);
    expect(flags(), [77, 78]);

    h.page(1, const []);
    await reports.load();
    expect(reports.state.status, CommunityReportsStatus.empty);

    h.pageFails(1);
    await reports.load();
    expect(reports.state.status, CommunityReportsStatus.failure);
  });

  test('the next page adds its reports, each flag once', () async {
    h
      ..page(1, [reportedComment], totalPages: 2)
      ..page(2, [reportedComment, reportedReply], totalPages: 2);
    await reports.load();
    await reports.loadMore();

    expect(flags(), [77, 78]);
    expect(reports.state.hasMore, isFalse);
  });

  test('Keep: the flag is dismissed and its row leaves; her badges are read '
      'again; the last one leaves «none waiting»', () async {
    h.page(1, [reportedComment, reportedReply]);
    await reports.load();

    await reports.keep(reportedReply);
    expect(flags(), [77]);
    expect(reports.state.event, CommunityReportsEvent.keptReply);
    await reports.keep(reportedComment);

    verify(() => h.dismiss(77)).called(1);
    expect(reports.state.event, CommunityReportsEvent.kept);
    expect(reports.state.status, CommunityReportsStatus.empty);
    expect(h.badgesRead, 2);
  });

  test(
    'Delete a comment: its row and its replies\' rows leave (D16)',
    () async {
      h.page(1, [reportedComment, reportedReply]);
      await reports.load();

      await reports.delete(reportedComment);

      verify(() => h.delete(10)).called(1);
      expect(flags(), isEmpty);
      expect(reports.state.event, CommunityReportsEvent.deleted);
    },
  );

  test('a failure keeps the row and says so; a second tap while one is on '
      'its way does nothing', () async {
    h.page(1, [reportedComment, reportedReply]);
    when(
      () => h.dismiss(77),
    ).thenAnswer((_) async => const Left(OfflineFailure()));
    when(
      () => h.delete(100),
    ).thenAnswer((_) async => const Left(OfflineFailure()));
    await reports.load();

    await Future.wait([
      reports.keep(reportedComment),
      reports.keep(reportedComment),
    ]);
    expect(reports.state.event, CommunityReportsEvent.keepFailed);
    await reports.delete(reportedReply);

    verify(() => h.dismiss(77)).called(1);
    expect(flags(), [77, 78]);
    expect(reports.state.event, CommunityReportsEvent.deleteReplyFailed);
    expect(reports.state.answering, isEmpty);
    expect(h.badgesRead, 0);
  });

  test('read again on her return (S17): the rows stay if that fails', () async {
    h.page(1, [reportedComment, reportedReply]);
    await reports.load();

    h.page(1, [reportedReply]);
    await reports.reload();
    expect(flags(), [78]);

    h.pageFails(1);
    await reports.reload();
    expect(flags(), [78]);
    expect(reports.state.status, CommunityReportsStatus.loaded);
  });

  test('a reply under another comment stays when that comment goes', () async {
    final other = flaggedItem(79, testReply(id: 120, parentId: 12));
    h.page(1, [reportedComment, other]);
    await reports.load();

    await reports.delete(reportedComment);

    expect(flags(), [79]);
  });
}
