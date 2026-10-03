import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_nav.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/community_page.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/presentation/widgets/feed/community_feed_skeleton.dart';
import 'package:qeran/features/community/presentation/widgets/post_card/community_post_card.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../fixtures/community_post_fixtures.dart';
import '../blocs/feed/feed_cubit_harness.dart';
import 'feed_screen_rig.dart';

void main() {
  late FeedHarness h;
  setUpAll(initShippedStrings);
  setUp(() => h = FeedHarness());
  tearDown(() => h.dispose());

  for (final MapEntry(key: locale, value: copy) in feedLocales.entries) {
    final lang = locale.languageCode;

    testWidgets('B1, B10: the title, the posts, the end line [$lang]', (
      tester,
    ) async {
      h.page(1, [testPost(id: 2), testPost(id: 1, text: englishText)]);
      await h.cubit.load();
      await pumpFeed(tester, h, locale: locale);

      expect(find.text(copy.title), findsOneWidget);
      expect(find.text(copy.subtitle), findsOneWidget);
      expect(find.byType(CommunityPostCard), findsNWidgets(2));
      expect(find.text(copy.end), findsOneWidget);
    });

    testWidgets('B4: no posts — the title stays, the empty state under it '
        '[$lang]', (tester) async {
      h.page(1, const []);
      await h.cubit.load();
      await pumpFeed(tester, h, locale: locale);

      expect(find.text(copy.title), findsOneWidget);
      expect(find.text(copy.emptyTitle), findsOneWidget);
      expect(find.text(copy.end), findsNothing);
    });

    testWidgets('B5: the error state, and its retry asks again [$lang]', (
      tester,
    ) async {
      h.pageFails(1);
      await h.cubit.load();
      await pumpFeed(tester, h, locale: locale);
      expect(find.text(copy.errorTitle), findsOneWidget);

      h.page(1, [testPost()]);
      await tester.tap(find.text(copy.retry));
      await tester.pumpAndSettle();

      expect(find.byType(CommunityPostCard), findsOneWidget);
    });
  }

  testWidgets('B3: two skeleton cards while the first page loads', (
    tester,
  ) async {
    final never = Completer<Either<Failure, CommunityPage<CommunityPost>>>();
    when(() => h.getFeed(page: 1)).thenAnswer((_) => never.future);
    unawaited(h.cubit.load());
    await pumpFeed(tester, h, settle: false);

    expect(find.byType(CommunityFeedSkeleton), findsNWidgets(2));
  });

  testWidgets('B2: the list ends clear of the bottom nav', (tester) async {
    h.page(1, [testPost()]);
    await h.cubit.load();
    await pumpFeed(tester, h);

    final clearance = QeranBottomNav.contentClearance(
      tester.element(find.byType(CustomScrollView)),
    );
    expect(
      find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.height == clearance,
        ),
      ),
      findsOneWidget,
    );
  });
}
