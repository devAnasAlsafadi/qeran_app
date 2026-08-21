import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/badges/domain/entities/badge_tab_keys.dart';
import 'package:qeran/features/badges/domain/usecases/get_badges_usecase.dart';
import 'package:qeran/features/badges/domain/usecases/mark_tab_seen_usecase.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/features/matchmaker/shared/presentation/widgets/matchmaker_count_badge.dart';
import 'package:qeran/features/matchmaker/users/domain/entities/matchmaker_users_list.dart';
import 'package:qeran/features/matchmaker/users/presentation/widgets/matchmaker_users_segmented_tabs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Users tab carries TWO numbers that look alike and mean different
/// things:
///   * the nav dot — activity since the last visit, cleared by visiting;
///   * the «بالانتظار» count — a queue of work still to do, cleared by doing
///     the work.
///
/// Opening the tab clears the first and leaves the second standing. Collapsing
/// them into one source is the tidy-looking change that would break it, so
/// this pins the segment's count as independent of the badges cubit.
/// `pending_badge_refresh_test.dart` covers the other half — that the count
/// itself refetches once the work is done.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

class _FakeGetBadges extends Fake implements GetBadgesUseCase {}

class _FakeMarkTabSeen extends Fake implements MarkTabSeenUseCase {}

class _FakeBadgesCubit extends BadgesCubit {
  _FakeBadgesCubit()
    : super(getBadges: _FakeGetBadges(), markTabSeen: _FakeMarkTabSeen());

  /// Local half only — the server call is not what this is about.
  @override
  Future<void> markSeen(String tabKey) async => emit(state.cleared(tabKey));
}

Future<void> _pump(WidgetTester tester, int pendingBadge) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar')],
      startLocale: const Locale('ar'),
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: Scaffold(
            body: MatchmakerUsersSegmentedTabs(
              active: MatchmakerUsersList.pending,
              onChanged: (_) {},
              pendingBadge: pendingBadge,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('clearing the nav dot leaves the pending count standing', (
    tester,
  ) async {
    final badges = _FakeBadgesCubit();
    addTearDown(badges.close);
    badges.applyUpdate(BadgeTabKeys.users, 2);

    await _pump(tester, 4);
    // What opening the Users tab does.
    await badges.markSeen(BadgeTabKeys.users);
    await tester.pumpAndSettle();

    expect(badges.state.users, 0, reason: 'the nav dot clears');
    expect(find.byType(MatchmakerCountBadge), findsOneWidget);
    expect(find.text('4'), findsOneWidget, reason: 'the workload does not');
  });
}
