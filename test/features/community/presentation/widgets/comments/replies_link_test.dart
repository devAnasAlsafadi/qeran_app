import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/features/community/presentation/blocs/comments/comment_thread.dart';
import 'package:qeran/features/community/presentation/blocs/comments/comment_threads.dart';
import 'package:qeran/features/community/presentation/widgets/comments/comment_row.dart';
import 'package:qeran/features/community/presentation/widgets/comments/replies_link.dart';

import '../../../../../core/shipped_strings_rig.dart';
import '../../../fixtures/community_comment_fixtures.dart';

/// [thread]'s link in a phone-wide column, in [locale]'s UI; returns how
/// many times it asked for replies.
Future<List<int>> _pump(
  WidgetTester tester,
  CommentThread thread, {
  Locale locale = const Locale('en'),
}) async {
  final asks = <int>[];
  await pumpShippedStrings(
    tester,
    locale,
    settle: thread.repliesStatus != RepliesStatus.loading,
    child: Center(
      child: SizedBox(
        width: 390,
        child: RepliesLink(thread: thread, onShow: () => asks.add(1)),
      ),
    ),
  );
  return asks;
}

/// [replyCount] replies, none shown.
CommentThread _collapsed(int replyCount) =>
    CommentThread(testComment(replyCount: replyCount));

/// [shown] of [total] replies shown.
CommentThread _open(int shown, int total) => withRepliesPage(
  _collapsed(total),
  commentPage(
    [for (var i = 0; i < shown; i++) testReply(id: 100 + i)],
    totalPages: shown < total ? 2 : 1,
    totalCount: total,
  ),
);

void main() {
  setUpAll(initShippedStrings);

  group('before any reply is shown: «عرض الردود», counted (Q5)', () {
    final cases = {
      1: ('عرض الردّ', 'View 1 reply'),
      2: ('عرض الردّين', 'View 2 replies'),
      3: ('عرض 3 ردود', 'View 3 replies'),
      11: ('عرض 11 ردّاً', 'View 11 replies'),
    };
    for (final MapEntry(key: n, value: (ar, en)) in cases.entries) {
      testWidgets('$n, ar', (tester) async {
        await _pump(tester, _collapsed(n), locale: const Locale('ar'));
        expect(find.text(ar), findsOneWidget);
      });

      testWidgets('$n, en', (tester) async {
        await _pump(tester, _collapsed(n));
        expect(find.text(en), findsOneWidget);
      });
    }
  });

  group('more on the server: «عرض ردود أخرى», the ones not shown', () {
    testWidgets('ar', (tester) async {
      await _pump(tester, _open(2, 3), locale: const Locale('ar'));
      expect(find.text('عرض ردّ آخر'), findsOneWidget);
    });

    testWidgets('en', (tester) async {
      await _pump(tester, _open(1, 3));
      expect(find.text('View 2 more replies'), findsOneWidget);
    });
  });

  testWidgets('every reply shown, or none to show: nothing', (tester) async {
    await _pump(tester, _open(3, 3));
    expect(find.byType(InkWell), findsNothing);

    await _pump(tester, _collapsed(0));
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('a tap asks for them; the link lines up with the replies', (
    tester,
  ) async {
    final asks = await _pump(tester, _collapsed(3));

    await tester.tap(find.text('View 3 replies'));

    expect(asks, hasLength(1));
    final link = tester.getRect(find.byType(RepliesLink));
    final line = tester.getRect(
      find.descendant(
        of: find.byType(RepliesLink),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(line.left - link.left, CommentRow.replyIndent);
  });

  testWidgets('a page on its way: a loader', (tester) async {
    await _pump(
      tester,
      _collapsed(3).copyWith(repliesStatus: RepliesStatus.loading),
    );

    expect(find.byType(QeranLoader), findsOneWidget);
    expect(find.text('View 3 replies'), findsNothing);
  });

  testWidgets('a page failed: says so, and its retry asks again', (
    tester,
  ) async {
    final asks = await _pump(
      tester,
      _collapsed(3).copyWith(repliesStatus: RepliesStatus.failed),
    );
    expect(find.text("Couldn't load more."), findsOneWidget);

    await tester.tap(find.text('Retry'));

    expect(asks, hasLength(1));
  });
}
