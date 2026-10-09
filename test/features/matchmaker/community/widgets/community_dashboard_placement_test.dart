import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/badges/domain/usecases/get_badges_usecase.dart';
import 'package:qeran/features/badges/domain/usecases/mark_tab_seen_usecase.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/features/community/domain/entities/community_config.dart';
import 'package:qeran/features/community/domain/entities/community_post_change.dart';
import 'package:qeran/features/community/domain/entities/post_publish_outcome.dart';
import 'package:qeran/features/community/domain/usecases/has_my_community_posts_usecase.dart';
import 'package:qeran/features/community/domain/usecases/watch_community_post_changes_usecase.dart';
import 'package:qeran/features/matchmaker/community/presentation/blocs/dashboard/community_dashboard_cubit.dart';
import 'package:qeran/features/matchmaker/community/presentation/screens/matchmaker_community_screen.dart';
import 'package:qeran/features/matchmaker/community/presentation/widgets/dashboard/community_dashboard_section.dart';
import 'package:qeran/features/matchmaker/dashboard/domain/entities/matchmaker_dashboard_stats.dart';
import 'package:qeran/features/matchmaker/dashboard/presentation/widgets/matchmaker_dashboard_body.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../../community/fixtures/community_post_fixtures.dart';
import '../community_screen_rig.dart';
import '../composer_rig.dart';

class _FakeGet extends Fake implements GetBadgesUseCase {}

class _FakeMark extends Fake implements MarkTabSeenUseCase {}

class _MockHasPosts extends Mock implements HasMyCommunityPostsUseCase {}

class _MockWatch extends Mock implements WatchCommunityPostChangesUseCase {}

const _stats = MatchmakerDashboardStats(
  pendingUsersCount: 0,
  approvedSubscribedCount: 1,
  approvedUnsubscribedCount: 10,
  activeCompatibilityCasesCount: 0,
  unreadMessagesCount: 2,
  totalAssignedUsers: 11,
);

/// Where the section sits, and «منشور جديد» from the Dashboard (A2, Q7).
void main() {
  late BadgesCubit badges;
  late CommunityScreenHarness h;
  setUpAll(initShippedStrings);
  setUp(() {
    h = CommunityScreenHarness();
    badges = BadgesCubit(getBadges: _FakeGet(), markTabSeen: _FakeMark());
    sl.registerSingleton<BadgesCubit>(badges);
  });
  tearDown(() async {
    await badges.close();
    await h.dispose();
  });

  Future<void> pump(WidgetTester tester, Widget child) {
    final hasPosts = _MockHasPosts();
    when(hasPosts.call).thenAnswer((_) async => const Right(true));
    final watch = _MockWatch();
    when(
      watch.call,
    ).thenAnswer((_) => const Stream<CommunityPostChange>.empty());
    return pumpHerApp(
      tester,
      BlocProvider(
        create: (_) =>
            CommunityDashboardCubit(hasPosts: hasPosts, watchChanges: watch)
              ..load(),
        child: child,
      ),
    );
  }

  testWidgets('right after «تحتاج انتباهكِ», before «نظرة عامة»; nothing '
      'else in the body moves', (tester) async {
    final context = await pumpShippedStrings(tester, const Locale('en'));
    final body =
        MatchmakerDashboardBody(
              stats: _stats,
              matchmakerName: 'Anosa',
              onOpen: (index, {usersSubTab}) {},
            ).build(context)
            as ListView;
    final children =
        (body.childrenDelegate as SliverChildListDelegate).children;

    expect(
      [for (final c in children) c.runtimeType.toString()],
      [
        'MatchmakerGreetingRow',
        'SizedBox',
        'QeranSectionHeader',
        'SizedBox',
        'IntrinsicHeight',
        'SizedBox',
        'CommunityDashboardSection',
        'SizedBox',
        'QeranSectionHeader',
        'SizedBox',
        'MatchmakerOverviewGrid',
      ],
    );
  });

  testWidgets('«New post» from the Dashboard: published, she lands on «My '
      'posts» with her post first and the toast (Q7)', (tester) async {
    final composer = ComposerHarness()
      ..configure(const CommunityConfig(postTextMaxLength: 2000))
      ..publishes(Right(PostPublished(testPost(id: 31))));
    addTearDown(composer.guidelines.dispose);
    h.myPage(1, [testPost(id: 31, text: 'Just now')]);
    h.all.page(1, [testPost(id: 1)]);
    await pump(
      tester,
      const SingleChildScrollView(child: CommunityDashboardSection()),
    );

    await tester.tap(find.text('New post'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'إرشاد');
    await tester.pump();
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    final screen = tester.widget<MatchmakerCommunityScreen>(
      find.byType(MatchmakerCommunityScreen),
    );
    expect(screen.initialTab, MatchmakerCommunityTab.mine);
    expect(find.text('Just now'), findsOneWidget);
    expect(find.text('Your post is published.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
