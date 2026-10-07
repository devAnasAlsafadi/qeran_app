import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/community_comment.dart';
import 'package:qeran/features/community/domain/entities/community_flag.dart';
import 'package:qeran/features/community/domain/entities/community_flagged_item.dart';
import 'package:qeran/features/community/domain/entities/community_page.dart';
import 'package:qeran/features/community/domain/usecases/delete_community_comment_usecase.dart';
import 'package:qeran/features/community/domain/usecases/dismiss_community_flag_usecase.dart';
import 'package:qeran/features/community/domain/usecases/get_community_flags_usecase.dart';
import 'package:qeran/features/matchmaker/community/presentation/blocs/reports/community_reports_cubit.dart';
import 'package:qeran/features/report/domain/entities/report_reason.dart';

import '../../community/fixtures/community_comment_fixtures.dart';

class _MockGetFlags extends Mock implements GetCommunityFlagsUseCase {}

class _MockDismiss extends Mock implements DismissCommunityFlagUseCase {}

class _MockDelete extends Mock implements DeleteCommunityCommentUseCase {}

/// A report on [comment] (flag [flagId]) in post 1, «Is it…» its start.
CommunityFlaggedItem flaggedItem(
  int flagId,
  CommunityComment comment, {
  int count = 2,
  ReportReason reason = ReportReason.harassment,
  DateTime? at,
}) => CommunityFlaggedItem(
  flag: CommunityFlag(
    id: flagId,
    reportCount: count,
    topReason: reason,
    lastReportedAt: at,
  ),
  comment: comment,
  postId: 1,
  postSnippet: 'الاستخارة والاستشارة',
);

/// «البلاغات»'s cubit over scripted use cases: Keep and Delete succeed
/// unless told otherwise.
class ReportsHarness {
  ReportsHarness() {
    when(() => dismiss(any())).thenAnswer((_) async => const Right(unit));
    when(() => delete(any())).thenAnswer((_) async => const Right(unit));
  }

  final getFlags = _MockGetFlags();
  final dismiss = _MockDismiss();
  final delete = _MockDelete();
  int badgesRead = 0;

  CommunityReportsCubit newCubit() => CommunityReportsCubit(
    getFlags: getFlags,
    dismissFlag: dismiss,
    deleteComment: delete,
    onFlagCleared: () => badgesRead++,
  );

  /// Page [page] answers with [items], of [totalPages].
  void page(int page, List<CommunityFlaggedItem> items, {int totalPages = 1}) =>
      when(() => getFlags(page: page)).thenAnswer(
        (_) async => Right(
          CommunityPage(
            items: items,
            pageNumber: page,
            pageSize: 20,
            totalCount: items.length,
            totalPages: totalPages,
          ),
        ),
      );

  void pageFails(int page) => when(() => getFlags(page: page)).thenAnswer(
    (_) async => const Left<Failure, CommunityPage<CommunityFlaggedItem>>(
      OfflineFailure(),
    ),
  );
}

/// X's comment 10 reported twice, and a reply under it reported once.
final reportedComment = flaggedItem(77, testComment(id: 10, author: fahad));
final reportedReply = flaggedItem(
  78,
  testReply(id: 100, parentId: 10, author: sara),
  count: 1,
  reason: ReportReason.contactDetails,
);
