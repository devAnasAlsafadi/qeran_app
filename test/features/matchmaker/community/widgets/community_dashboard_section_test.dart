import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/badges/domain/entities/badge_tab_keys.dart';
import 'package:qeran/features/badges/domain/usecases/get_badges_usecase.dart';
import 'package:qeran/features/badges/domain/usecases/mark_tab_seen_usecase.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/features/community/domain/entities/community_post_change.dart';
import 'package:qeran/features/community/domain/usecases/has_my_community_posts_usecase.dart';
import 'package:qeran/features/community/domain/usecases/watch_community_post_changes_usecase.dart';
import 'package:qeran/features/matchmaker/community/presentation/blocs/dashboard/community_dashboard_cubit.dart';
import 'package:qeran/features/matchmaker/community/presentation/blocs/reports/community_reports_cubit.dart';
import 'package:qeran/features/matchmaker/community/presentation/screens/community_reports_page.dart';
import 'package:qeran/features/matchmaker/community/presentation/screens/matchmaker_community_screen.dart';
import 'package:qeran/features/matchmaker/community/presentation/widgets/dashboard/community_dashboard_section.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../../community/fixtures/community_post_fixtures.dart';
import '../community_screen_rig.dart';
import '../reports_rig.dart';

class _FakeGet extends Fake implements GetBadgesUseCase {}

class _FakeMark extends Fake implements MarkTabSeenUseCase {}

class _MockHasPosts extends Mock implements HasMyCommunityPostsUseCase {}

class _MockWatch extends Mock implements WatchCommunityPostChangesUseCase {}

final _copy = {
  'ar': (
    title: 'المجتمع',
    subtitle: 'منشوراتكِ وما يحتاج قراركِ فيها',
    comments: 'تعليقات جديدة على منشوراتكِ',
    reports: 'بلاغات بانتظار قراركِ',
    noPosts: 'ليس لديكِ منشورات الآن. شاركي إرشاداً مع الأعضاء.',
    newPost: 'منشور جديد',
  ),
  'en': (
    title: 'Community',
    subtitle: 'Your posts and what needs your decision',
    comments: 'New comments on your posts',
    reports: 'Reports awaiting your decision',
    noPosts: 'You have no posts right now. Share guidance with members.',
    newPost: 'New post',
  ),
};

/// Her Dashboard's «المجتمع» (A2–A4).
void main() {
  late BadgesCubit badges;
  late CommunityScreenHarness h;
  late ReportsHarness reports;
  late _MockHasPosts hasPosts;
  setUpAll(initShippedStrings);
  setUp(() {
    h = CommunityScreenHarness();
    badges = BadgesCubit(getBadges: _FakeGet(), markTabSeen: _FakeMark());
    sl.registerSingleton<BadgesCubit>(badges);
    reports = ReportsHarness()..page(1, const []);
    sl.registerFactory<CommunityReportsCubit>(reports.newCubit);
    hasPosts = _MockHasPosts();
    when(hasPosts.call).thenAnswer((_) async => const Right(true));
  });
  tearDown(() async {
    await badges.close();
    await h.dispose();
  });

  Future<void> pump(WidgetTester tester, String language) async {
    final watch = _MockWatch();
    when(
      watch.call,
    ).thenAnswer((_) => const Stream<CommunityPostChange>.empty());
    await pumpHerApp(
      tester,
      BlocProvider(
        create: (_) =>
            CommunityDashboardCubit(hasPosts: hasPosts, watchChanges: watch)
              ..load(),
        child: const SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: CommunityDashboardSection(),
        ),
      ),
      locale: Locale(language),
    );
    await tester.pump();
  }

  Color countColor(WidgetTester tester, String count) =>
      tester.widget<Text>(find.text(count)).style!.color!;

  for (final MapEntry(key: language, value: t) in _copy.entries) {
    testWidgets(
      'A2 [$language]: «${t.title}» + «${t.subtitle}», «${t.comments}» '
      '3 and «${t.reports}» 2 (gold), «${t.title}» and «${t.newPost}»',
      (tester) async {
        badges
          ..applyUpdate(BadgeTabKeys.communityComments, 3)
          ..applyUpdate(BadgeTabKeys.communityReports, 2);
        await pump(tester, language);

        expect(find.text(t.subtitle), findsOneWidget);
        expect(find.text(t.comments), findsOneWidget);
        expect(find.text(t.reports), findsOneWidget);
        expect(countColor(tester, '3'), QeranColors.wine);
        expect(countColor(tester, '2'), QeranColors.goldDeep);
        expect(find.byIcon(Icons.flag_rounded), findsOneWidget);
        expect(find.text(t.title), findsNWidgets(2));
        expect(find.text(t.newPost), findsOneWidget);
      },
    );

    testWidgets('A4 [$language]: no posts now — «${t.noPosts}» in place of '
        'both rows; the buttons stay', (tester) async {
      when(hasPosts.call).thenAnswer((_) async => const Right(false));
      await pump(tester, language);

      expect(find.text(t.noPosts), findsOneWidget);
      expect(find.text(t.comments), findsNothing);
      expect(find.text(t.reports), findsNothing);
      expect(find.text(t.newPost), findsOneWidget);
    });
  }

  testWidgets('A3: nothing new — both counts 0 in faint ink, the flag '
      'outlined; a failed read keeps the rows', (tester) async {
    when(hasPosts.call).thenAnswer((_) async => const Left(OfflineFailure()));
    await pump(tester, 'en');

    expect(tester.widgetList<Text>(find.text('0')).map((t) => t.style!.color), [
      QeranColors.inkFaint,
      QeranColors.inkFaint,
    ]);
    expect(find.byIcon(Icons.outlined_flag_rounded), findsOneWidget);
    expect(find.text('New comments on your posts'), findsOneWidget);
  });

  testWidgets('the rows and «Community» open her screens: «منشوراتي», '
      '«البلاغات», All posts', (tester) async {
    h.myPage(1, const []);
    h.all.page(1, [testPost(id: 1)]);
    await pump(tester, 'en');

    await tester.tap(find.text('New comments on your posts'));
    await tester.pumpAndSettle();
    final screen = tester.widget<MatchmakerCommunityScreen>(
      find.byType(MatchmakerCommunityScreen),
    );
    expect(screen.initialTab, MatchmakerCommunityTab.mine);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reports awaiting your decision'));
    await tester.pumpAndSettle();
    expect(find.byType(CommunityReportsScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Community').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MatchmakerCommunityScreen>(
            find.byType(MatchmakerCommunityScreen),
          )
          .initialTab,
      MatchmakerCommunityTab.all,
    );
  });
}
