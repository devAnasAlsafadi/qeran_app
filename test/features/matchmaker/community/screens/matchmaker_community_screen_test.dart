import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/widgets/qeran_app_bar.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_floating_button.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/community_page.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/domain/entities/post_publish_outcome.dart';
import 'package:qeran/features/community/presentation/widgets/feed/community_feed_skeleton.dart';
import 'package:qeran/features/matchmaker/community/presentation/screens/matchmaker_community_screen.dart';
import 'package:qeran/features/matchmaker/community/presentation/screens/post_composer_screen.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../../community/fixtures/community_post_fixtures.dart';
import '../community_screen_rig.dart';
import '../composer_rig.dart';

const _ar = Locale('ar');
const _en = Locale('en');

/// Each language's words for her Community screen (B1–B5).
final _copy = {
  _ar: (
    title: 'المجتمع',
    all: 'كل المنشورات',
    mine: 'منشوراتي',
    memberSubtitle: 'إرشادات تنشرها خطّابات قِران',
    emptyTitle: 'ليس لديكِ منشورات الآن',
    emptyBody: 'شاركي إرشاداً للأعضاء بنص أو صور أو فيديو.',
    errorTitle: 'تعذّر تحميل منشوراتكِ',
    errorBody: 'تحقّقي من اتصالكِ بالإنترنت وحاولي مرة أخرى.',
    retry: 'حاولي مرة أخرى',
  ),
  _en: (
    title: 'Community',
    all: 'All posts',
    mine: 'My posts',
    memberSubtitle: "Guidance published by Qeran's matchmakers",
    emptyTitle: 'You have no posts right now',
    emptyBody: 'Share guidance with members as text, images or a video.',
    errorTitle: "Couldn't load your posts",
    errorBody: 'Check your connection and try again.',
    retry: 'Try again',
  ),
};

void main() {
  late CommunityScreenHarness h;
  setUpAll(initShippedStrings);
  setUp(() {
    h = CommunityScreenHarness();
    h.all.page(1, [testPost(id: 1, text: englishText)]);
  });
  tearDown(() => h.dispose());

  Future<void> open(
    WidgetTester tester, {
    Locale locale = _en,
    MatchmakerCommunityTab tab = MatchmakerCommunityTab.all,
    bool settle = true,
  }) => pumpHerApp(
    tester,
    MatchmakerCommunityScreen(initialTab: tab),
    locale: locale,
    settle: settle,
  );

  for (final locale in [_ar, _en]) {
    final t = _copy[locale]!;

    testWidgets('B1 [${locale.languageCode}]: «${t.title}» with its two '
        'segments; All posts is the feed as she reads it', (tester) async {
      await open(tester, locale: locale);

      expect(
        find.descendant(
          of: find.byType(QeranAppBar),
          matching: find.text(t.title),
        ),
        findsOneWidget,
      );
      expect(find.text(t.all), findsOneWidget);
      expect(find.text(t.mine), findsOneWidget);
      expect(find.text(englishText), findsOneWidget);
      expect(find.text(t.memberSubtitle), findsNothing);
      verifyNever(() => h.getMyPosts(page: any(named: 'page')));
    });

    testWidgets('B4 [${locale.languageCode}]: nothing in «منشوراتي» says '
        'what she has now (Q12)', (tester) async {
      h.myPage(1, const []);
      await open(tester, locale: locale, tab: MatchmakerCommunityTab.mine);

      expect(find.text(t.emptyTitle), findsOneWidget);
      expect(find.text(t.emptyBody), findsOneWidget);
    });

    testWidgets('B5 [${locale.languageCode}]: «منشوراتي» failed, and its '
        'retry asks again', (tester) async {
      h.myPageFails();
      await open(tester, locale: locale, tab: MatchmakerCommunityTab.mine);
      expect(find.text(t.errorTitle), findsOneWidget);
      expect(find.text(t.errorBody), findsOneWidget);

      h.myPage(1, [testPost(id: 5)]);
      await tester.tap(find.text(t.retry));
      await tester.pumpAndSettle();

      expect(find.text(t.errorTitle), findsNothing);
      verify(() => h.getMyPosts(page: 1)).called(2);
    });
  }

  testWidgets('B2: «منشوراتي» loads the first time she opens it, and every '
      'opening clears her new comments (D33)', (tester) async {
    h.myPage(1, [testPost(id: 5, text: 'Mine')]);
    await open(tester);

    await tester.tap(find.text('My posts'));
    await tester.pumpAndSettle();
    expect(find.text('Mine'), findsOneWidget);
    await tester.tap(find.text('All posts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My posts'));
    await tester.pumpAndSettle();

    verify(() => h.getMyPosts(page: 1)).called(1);
    expect(h.seen, 2);
  });

  testWidgets('B3: «منشوراتي» loading shows the card skeletons', (
    tester,
  ) async {
    final never = Completer<Either<Failure, CommunityPage<CommunityPost>>>();
    when(() => h.getMyPosts(page: 1)).thenAnswer((_) => never.future);
    await open(tester, tab: MatchmakerCommunityTab.mine, settle: false);

    expect(find.byType(CommunityFeedSkeleton), findsWidgets);
  });

  testWidgets('opened on «منشوراتي» (the Dashboard row, after publishing): '
      'read and seen at once', (tester) async {
    h.myPage(1, [testPost(id: 5, text: 'Mine')]);
    await open(tester, tab: MatchmakerCommunityTab.mine);

    expect(find.text('Mine'), findsOneWidget);
    expect(h.seen, 1);
  });

  group('«منشور جديد»', () {
    late ComposerHarness composer;
    setUp(() => composer = ComposerHarness());

    testWidgets('B1: floats on All posts; published, she lands on «منشوراتي» '
        'with her post first and «تم نشر منشوركِ.» (Q7, D5)', (tester) async {
      composer.publishes(Right(PostPublished(testPost(id: 31))));
      h.myPage(1, [
        testPost(id: 31, text: 'Just now'),
        testPost(id: 5, text: 'Mine'),
      ]);
      await open(tester, locale: _ar);
      expect(find.byType(QeranFloatingButton), findsOneWidget);

      await tester.tap(find.text('منشور جديد'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'إرشاد');
      await tester.pump();
      await tester.tap(find.text('نشر'));
      await tester.pumpAndSettle();

      expect(find.byType(PostComposerScreen), findsNothing);
      expect(find.text('Just now'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Just now')).dy,
        lessThan(tester.getTopLeft(find.text('Mine')).dy),
      );
      expect(find.text('تم نشر منشوركِ.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('B4: an empty «منشوراتي» has its own button, not the floating '
        'one', (tester) async {
      h.myPage(1, const []);
      await open(tester, tab: MatchmakerCommunityTab.mine);

      expect(find.byType(QeranFloatingButton), findsNothing);
      await tester.tap(find.widgetWithText(QeranButton, 'New post'));
      await tester.pumpAndSettle();

      expect(find.byType(PostComposerScreen), findsOneWidget);
    });
  });
}
