import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/badges/domain/entities/badge_tab_keys.dart';
import 'package:qeran/features/badges/domain/usecases/get_badges_usecase.dart';
import 'package:qeran/features/badges/domain/usecases/mark_tab_seen_usecase.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/features/matchmaker/community/presentation/screens/matchmaker_community_screen.dart';
import 'package:qeran/features/matchmaker/community/presentation/widgets/community_header_action.dart';
import 'package:qeran/features/matchmaker/shared/presentation/widgets/matchmaker_app_bar.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../../community/fixtures/community_post_fixtures.dart';
import '../community_screen_rig.dart';

class _FakeGet extends Fake implements GetBadgesUseCase {}

class _FakeMark extends Fake implements MarkTabSeenUseCase {}

/// The gold dot: the only gold circle on the icon.
Finder get _dot => find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration! as BoxDecoration).color == QeranColors.gold &&
      (w.decoration! as BoxDecoration).shape == BoxShape.circle,
);

/// The count lands on the cubit's stream in a microtask during the first
/// frame; the second draws it.
Future<void> _settleUpdate(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

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

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) => pumpHerApp(
    tester,
    const Align(
      alignment: AlignmentDirectional.topEnd,
      child: CommunityHeaderAction(),
    ),
    locale: locale,
  );

  for (final (locale, label) in [
    (const Locale('ar'), 'المجتمع'),
    (const Locale('en'), 'Community'),
  ]) {
    testWidgets('A1 [${locale.languageCode}]: «$label», no dot with nothing '
        'new (A3)', (tester) async {
      await pump(tester, locale: locale);

      expect(find.byTooltip(label), findsOneWidget);
      expect(find.byIcon(Icons.dynamic_feed_rounded), findsOneWidget);
      expect(_dot, findsNothing);
    });
  }

  testWidgets('a new comment alone lights the dot, live', (tester) async {
    await pump(tester);

    badges.applyUpdate(BadgeTabKeys.communityComments, 2);
    await _settleUpdate(tester);
    expect(_dot, findsOneWidget);
  });

  testWidgets('a report waiting alone lights it too; both back to 0 put it '
      'out', (tester) async {
    await pump(tester);

    badges.applyUpdate(BadgeTabKeys.communityReports, 1);
    await _settleUpdate(tester);
    expect(_dot, findsOneWidget);

    badges.applyUpdate(BadgeTabKeys.communityReports, 0);
    await _settleUpdate(tester);
    expect(_dot, findsNothing);
  });

  testWidgets('a tap opens her Community screen on All posts', (tester) async {
    h.all.page(1, [testPost(id: 1)]);
    await pump(tester);

    await tester.tap(find.byIcon(Icons.dynamic_feed_rounded));
    await tester.pumpAndSettle();

    final screen = tester.widget<MatchmakerCommunityScreen>(
      find.byType(MatchmakerCommunityScreen),
    );
    expect(screen.initialTab, MatchmakerCommunityTab.all);
  });

  for (final (locale, before) in [
    (const Locale('ar'), (double community, double bell) => community > bell),
    (const Locale('en'), (double community, double bell) => community < bell),
  ]) {
    testWidgets("every tab's header has it before the bell "
        '[${locale.languageCode}]', (tester) async {
      await pumpHerApp(
        tester,
        const SizedBox(
          height: kToolbarHeight,
          child: MatchmakerAppBar(title: 'Dashboard'),
        ),
        locale: locale,
      );

      final community = tester.getCenter(
        find.byIcon(Icons.dynamic_feed_rounded),
      );
      final bell = tester.getCenter(
        find.byIcon(Icons.notifications_none_rounded),
      );
      expect(before(community.dx, bell.dx), isTrue);
    });
  }
}
