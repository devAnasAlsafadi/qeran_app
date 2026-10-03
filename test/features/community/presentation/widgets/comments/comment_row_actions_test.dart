import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/domain/entities/community_comment.dart';
import 'package:qeran/features/community/presentation/blocs/comments/comment_thread.dart';
import 'package:qeran/features/community/presentation/widgets/comments/comment_row.dart';

import '../../../../../core/shipped_strings_rig.dart';
import '../../../fixtures/community_comment_fixtures.dart';

/// [comment]'s row, its taps counted.
Future<({List<String> taps})> _pump(
  WidgetTester tester,
  CommunityComment comment, {
  Locale locale = const Locale('en'),
  CommentDelivery? delivery,
  bool answerable = true,
}) async {
  final taps = <String>[];
  await pumpShippedStrings(
    tester,
    locale,
    child: Center(
      child: SizedBox(
        width: 390,
        child: CommentRow(
          comment: comment,
          delivery: delivery,
          onLike: () => taps.add('like'),
          onReply: answerable ? () => taps.add('reply') : null,
          onRetry: () => taps.add('retry'),
        ),
      ),
    ),
  );
  return (taps: taps);
}

double _textOpacity(WidgetTester tester, String text) => tester
    .widget<Opacity>(
      find.ancestor(of: find.text(text), matching: find.byType(Opacity)),
    )
    .opacity;

void main() {
  setUpAll(initShippedStrings);

  group('Reply, beside Like (D2)', () {
    testWidgets('«رد» on a comment', (tester) async {
      final row = await _pump(
        tester,
        testComment(),
        locale: const Locale('ar'),
      );

      await tester.tap(find.text('رد'));

      expect(row.taps, ['reply']);
    });

    testWidgets('none where it can\'t be answered (a reply, read-only)', (
      tester,
    ) async {
      await _pump(tester, testComment(), answerable: false);

      expect(find.text('Reply'), findsNothing);
      expect(find.text('Like'), findsOneWidget);
    });
  });

  testWidgets('on its way (D5): dimmed, «جارٍ النشر…», no actions', (
    tester,
  ) async {
    await _pump(
      tester,
      testComment(),
      locale: const Locale('ar'),
      delivery: CommentDelivery.pending,
    );

    expect(find.text('جارٍ النشر…'), findsOneWidget);
    expect(_textOpacity(tester, saraText), 0.6);
    expect(find.text('إعجاب'), findsNothing);
    expect(find.text('رد'), findsNothing);
  });

  testWidgets('failed (D7): dimmed, and the whole line sends it again', (
    tester,
  ) async {
    final row = await _pump(
      tester,
      testComment(),
      delivery: CommentDelivery.failed,
    );

    expect(_textOpacity(tester, saraText), 0.6);
    expect(find.text('Like'), findsNothing);
    final line = find.ancestor(
      of: find.text('Not posted · Tap to retry'),
      matching: find.byType(InkWell),
    );
    expect(tester.getSize(line).height, 44);
    await tester.tap(line);

    expect(row.taps, ['retry']);
  });
}
