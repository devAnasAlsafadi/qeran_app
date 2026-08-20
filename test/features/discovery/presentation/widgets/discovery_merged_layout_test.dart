import 'package:dartz/dartz.dart';
// easy_localization re-exports intl, whose TextDirection collides with
// dart:ui's — the one Directionality actually takes.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/chat/domain/entities/my_matchmaker_outcome.dart';
import 'package:qeran/features/chat/domain/repositories/chat_repository.dart';
import 'package:qeran/features/chat/domain/usecases/get_my_matchmaker_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/share_profile_usecase.dart';
import 'package:qeran/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:qeran/features/profile/presentation/blocs/share_with_matchmaker/share_with_matchmaker_cubit.dart';
import 'package:qeran/features/notifications/presentation/blocs/notification_badge_cubit.dart';
import 'package:qeran/features/profile/domain/entities/other_profile.dart';
import 'package:qeran/features/profile/domain/entities/placement.dart'
    as profile_placement;
import 'package:qeran/features/profile/domain/entities/placement_code.dart'
    as profile_code;
import 'package:qeran/features/profile/domain/entities/placement_item.dart'
    as profile_item;
import 'package:qeran/features/profile/domain/entities/placement_item_type.dart'
    as profile_item_type;
import 'package:qeran/features/profile/domain/entities/placement_value.dart'
    as profile_value;
import 'package:qeran/features/profile/domain/entities/profile_fetch_outcome.dart';
import 'package:qeran/features/profile/domain/repositories/profile_repository.dart';
import 'package:qeran/features/profile/domain/usecases/get_profile_by_id_usecase.dart';
import 'package:qeran/features/profile/presentation/widgets/full_profile_image_overlays.dart';
import 'package:qeran/features/profile/presentation/widgets/placement/qa_default_section.dart';
import 'package:qeran/features/subscriptions/domain/entities/current_subscription.dart';
import 'package:qeran/features/subscriptions/domain/usecases/get_current_subscription_usecase.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_page.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_profile.dart';
import 'package:qeran/features/discovery/domain/entities/like_outcome.dart';
import 'package:qeran/features/discovery/domain/entities/placement.dart'
    as discovery_placement;
import 'package:qeran/features/discovery/domain/entities/placement_code.dart'
    as discovery_code;
import 'package:qeran/features/discovery/domain/entities/placement_item.dart'
    as discovery_item;
import 'package:qeran/features/discovery/domain/entities/placement_item_type.dart'
    as discovery_item_type;
import 'package:qeran/features/discovery/domain/entities/placement_value.dart'
    as discovery_value;
import 'package:qeran/features/discovery/domain/usecases/fetch_discovery_page_usecase.dart';
import 'package:qeran/features/discovery/domain/usecases/like_profile_usecase.dart';
import 'package:qeran/features/discovery/domain/usecases/pass_profile_usecase.dart';
import 'package:qeran/features/discovery/domain/usecases/reset_skipped_profiles_usecase.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_cubit.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_hydration_cubit.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_state.dart';
import 'package:qeran/features/discovery/presentation/widgets/_image_overlay_button.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_action_bar.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_card.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_card_skeleton.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_chips_above_image.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_frosted_action_zone.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_merged_profile_body.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_unified_card.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Discovery + Full Profile are ONE screen.
///
/// What is pinned here: the photo runs edge to edge horizontally and takes the
/// top HALF of the viewport, starting just BELOW the status bar; the filter /
/// bell float ON the photo, bell at the START; there is no peek deck; the
/// first screenful ends after نبذة عني so everything from نبذة عن شريك الحياة
/// on sits below the fold; and the action cluster's backdrop only appears once
/// content is behind it.

/// A realistic status-bar inset, so "below the status bar" is actually
/// testable — the default test MediaQuery has zero padding.
const double kTopInset = 24.0;

// ── Fakes ────────────────────────────────────────────────────────────────────

/// Carries aboveImage chips and an aboutMe placement like the real deck
/// payload does, so the identity block and the content sheet have realistic
/// height and the geometry assertions below mean something.
DiscoveryProfile _profile(String id) => DiscoveryProfile(
  id: id,
  name: 'Name-$id',
  age: 25,
  images: const [],
  matchingScore: 27,
  placements: [
    discovery_placement.Placement(
      code: discovery_code.PlacementCode.aboveImage,
      name: 'فوق الصورة',
      items: [
        discovery_item.PlacementItem(
          questionId: 3,
          question: 'المهنة',
          type: discovery_item_type.PlacementItemType.text,
          value: const discovery_value.PlacementSingle('طبيب'),
          display: const discovery_value.PlacementSingle('طبيب'),
        ),
        discovery_item.PlacementItem(
          questionId: 4,
          question: 'الجنسية',
          type: discovery_item_type.PlacementItemType.text,
          value: const discovery_value.PlacementSingle('بحريني'),
          display: const discovery_value.PlacementSingle('بحريني'),
        ),
      ],
    ),
    discovery_placement.Placement(
      code: discovery_code.PlacementCode.aboutMe,
      name: 'نبذة عني',
      items: [
        discovery_item.PlacementItem(
          questionId: 11,
          question: 'نبذة عني',
          type: discovery_item_type.PlacementItemType.text,
          value: const discovery_value.PlacementSingle(kAboutMeBody),
          display: const discovery_value.PlacementSingle(kAboutMeBody),
        ),
      ],
    ),
  ],
);

/// What the DECK sends: a short preview, cut off by the server.
const String kAboutMeBody =
    'نص تعريفي طويل بما يكفي ليأخذ الجزء الأعلى من ورقة المحتوى، '
    'تمامًا كما يفعل النص الحقيقي القادم من الخادم في شاشة الاستكشاف.';

/// A نبذة short enough that photo + intro still fit inside one viewport, so
/// the fold group can measure the surplus it is there to measure. A long نبذة
/// legitimately has no surplus to give — see the group's own note.
const String kShortAboutMeBody = 'نبذة قصيرة.';

/// What the by-id profile sends: the paragraph the user actually wrote.
const String kFullAboutMeBody =
    'نص تعريفي طويل بما يكفي ليأخذ الجزء الأعلى من ورقة المحتوى، '
    'تمامًا كما يفعل النص الحقيقي القادم من الخادم في شاشة الاستكشاف. '
    'ويتضمن الحديث عن المستوى التعليمي والدورات والشهادات التي حصل عليها، '
    'وذكر عدد سنوات الخبرة العملية والجهات التي عمل معها.';

/// Everything falls back to echoing the key, EXCEPT the compatibility label —
/// that one is interpolated and sits in a fixed-width overlay pill, so the raw
/// key would overflow the row for reasons the screen is not responsible for.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {
        'profile': {'compatibility_label': '{percent}٪'},
        'discovery': {'action_undo_label': 'تراجع'},
      };
}

class _FakeFetch implements FetchDiscoveryPageUseCase {
  final List<DiscoveryProfile> _profiles;
  _FakeFetch(this._profiles);

  @override
  Future<Either<Failure, DiscoveryPage>> call({
    int page = 1,
    int pageSize = 10,
    Map<String, String>? filterParams,
  }) async => Right(
    DiscoveryPage(
      profiles: _profiles,
      pageNumber: 1,
      pageSize: _profiles.length,
      totalCount: _profiles.length,
      totalPages: 1,
    ),
  );
}

class _FakeLike implements LikeProfileUseCase {
  @override
  Future<Either<Failure, LikeOutcome>> call(String profileId) async =>
      const Right(LikeAccepted(likeId: '1'));
}

class _FakePass implements PassProfileUseCase {
  @override
  Future<Either<Failure, Unit>> call(String profileId) async =>
      const Right(unit);
}

/// Never invoked by these layout tests — the deck they drive is never empty.
class _FakeReset implements ResetSkippedProfilesUseCase {
  @override
  Future<Either<Failure, int>> call() async => const Right(0);
}

class _FakeGetCurrent implements GetCurrentSubscriptionUseCase {
  @override
  Future<Either<Failure, CurrentSubscription?>> call() async =>
      const Right(null);
}

class _FakeCurrentSubCubit extends CurrentSubscriptionCubit {
  _FakeCurrentSubCubit() : super(getCurrent: _FakeGetCurrent());
}

class _FakeGetNotifications extends Fake implements GetNotificationsUseCase {}

class _FakePrefs extends Fake implements SharedPrefService {}

class _FakeNotificationBadgeCubit extends NotificationBadgeCubit {
  _FakeNotificationBadgeCubit()
    : super(getNotifications: _FakeGetNotifications(), prefs: _FakePrefs());
  @override
  Future<void> refresh() async {}

  /// Stands in for "the server has something newer than last-seen".
  void setUnread(bool value) => emit(value);
}

/// The share CTA at the end of the merged scroll resolves its cubit from
/// GetIt; this keeps it in its unresolved state without any network.
class _FakeChatRepository extends Fake implements ChatRepository {
  @override
  Future<Either<Failure, MyMatchmakerOutcome>> getMyMatchmaker() async =>
      const Left(ServerFailure(message: 'errors.generic'));
}

/// Serves the by-id hydration behind the below-the-fold sections. [failing]
/// models the degrade path — the card must still render from the deck payload.
class _FakeProfileRepository extends Fake implements ProfileRepository {
  _FakeProfileRepository({
    this.failing = false,
    this.aboutMe = kFullAboutMeBody,
  });

  final bool failing;

  /// The نبذة عني the by-id profile carries. Length matters: the fold
  /// guarantees only apply while photo + نبذة still fit inside one viewport.
  final String aboutMe;

  final List<String> requested = [];

  @override
  Future<Either<Failure, ProfileFetchOutcome>> getProfileById(
    String userId,
  ) async {
    requested.add(userId);
    if (failing) return const Left(ServerFailure(message: 'errors.generic'));
    return Right(
      ProfileFetched(
        OtherProfile(
          id: userId,
          name: 'Name-$userId',
          age: 25,
          matchingScore: 52,
          images: const [],
          placements: [
            // The by-id profile carries the WHOLE نبذة عني; the deck only
            // sends the preview in [kAboutMeBody].
            profile_placement.Placement(
              code: profile_code.PlacementCode.aboutMe,
              name: 'نبذة عني',
              items: [
                profile_item.PlacementItem(
                  questionId: 11,
                  question: 'نبذة عني',
                  type: profile_item_type.PlacementItemType.text,
                  value: profile_value.PlacementSingle(aboutMe),
                  display: profile_value.PlacementSingle(aboutMe),
                ),
              ],
            ),
            profile_placement.Placement(
              code: profile_code.PlacementCode.defaultGroup,
              name: 'الدين ونمط الحياة',
              items: [
                profile_item.PlacementItem(
                  questionId: 7,
                  question: 'الديانة',
                  type: profile_item_type.PlacementItemType.select,
                  value: const profile_value.PlacementSingle('مسلمة'),
                  display: const profile_value.PlacementSingle('مسلمة'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<_FakeProfileRepository> _pumpView(
  WidgetTester tester,
  List<DiscoveryProfile> profiles, {
  bool hydrationFails = false,
  TextDirection direction = TextDirection.rtl,
  double topInset = kTopInset,
  String fullAboutMe = kFullAboutMeBody,
}) async {
  final profileRepo = _FakeProfileRepository(
    failing: hydrationFails,
    aboutMe: fullAboutMe,
  );
  sl.registerFactory<DiscoveryCubit>(
    () => DiscoveryCubit(
      fetchPage: _FakeFetch(profiles),
      likeProfile: _FakeLike(),
      passProfile: _FakePass(),
      resetSkipped: _FakeReset(),
    ),
  );
  sl.registerFactory<DiscoveryHydrationCubit>(
    () => DiscoveryHydrationCubit(
      getProfileById: GetProfileByIdUseCase(profileRepo),
    ),
  );
  sl.registerLazySingleton<NotificationBadgeCubit>(
    () => _FakeNotificationBadgeCubit(),
  );
  final chatRepo = _FakeChatRepository();
  sl.registerFactory<ShareWithMatchmakerCubit>(
    () => ShareWithMatchmakerCubit(
      getMyMatchmaker: GetMyMatchmakerUseCase(chatRepo),
      shareProfile: ShareProfileUseCase(chatRepo),
    ),
  );
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: Builder(
            builder: (inner) => MediaQuery(
              data: MediaQuery.of(inner).copyWith(
                padding: EdgeInsets.only(top: topInset),
                viewPadding: EdgeInsets.only(top: topInset),
              ),
              child: Directionality(
                textDirection: direction,
                child: BlocProvider<CurrentSubscriptionCubit>(
                  create: (_) => _FakeCurrentSubCubit(),
                  child: const Scaffold(body: DiscoveryView()),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return profileRepo;
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // `next` still drives the next photo's precache even though nothing peeks.
  group('DiscoveryLoaded.next', () {
    test('null when only one profile', () {
      final s = DiscoveryLoaded(
        profiles: [_profile('a')],
        currentIndex: 0,
        currentPage: 1,
        totalPages: 1,
      );
      expect(s.next, isNull);
    });

    test('returns second profile at index 0', () {
      final p1 = _profile('a');
      final p2 = _profile('b');
      final s = DiscoveryLoaded(
        profiles: [p1, p2],
        currentIndex: 0,
        currentPage: 1,
        totalPages: 1,
      );
      expect(s.next, equals(p2));
    });

    test('null when profile list is empty', () {
      final s = DiscoveryLoaded(
        profiles: const [],
        currentIndex: 0,
        currentPage: 1,
        totalPages: 1,
      );
      expect(s.next, isNull);
    });

    test('null when currentIndex is the last slot', () {
      final s = DiscoveryLoaded(
        profiles: [_profile('a'), _profile('b')],
        currentIndex: 1,
        currentPage: 1,
        totalPages: 1,
      );
      expect(s.next, isNull);
    });
  });

  group('merged full-bleed layout', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
    });

    setUp(() async => sl.reset());

    testWidgets('the photo starts BELOW the status bar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpView(tester, [_profile('a')]);

      // It must NOT run under the clock / wifi / battery. Flush to the safe
      // area, with no title bar between.
      final photo = tester.getRect(find.byType(DiscoveryImagePanel));
      expect(photo.top, kTopInset);
    });

    testWidgets('the photo runs edge to edge horizontally', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpView(tester, [_profile('a')]);

      final photo = tester.getRect(find.byType(DiscoveryImagePanel));
      // Was inset by 18dp on each side for the floating card.
      expect(photo.left, 0);
      expect(photo.right, 400);
    });

    testWidgets('the photo takes half the viewport, not most of it', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpView(tester, [_profile('a')]);

      final photoHeight = tester
          .getSize(find.byType(DiscoveryImagePanel))
          .height;
      // Half of what is VISIBLE — the viewport below the status bar, not the
      // raw screen.
      const visible = 800 - kTopInset;
      expect(photoHeight, closeTo(visible * kDiscoveryPhotoFraction, 0.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the peek deck is gone', (tester) async {
      await _pumpView(tester, [_profile('a'), _profile('b')]);

      expect(
        find.byKey(const ValueKey<String>('discovery-peek-silhouette')),
        findsNothing,
      );
      // One live card, never two.
      expect(find.byType(DiscoveryUnifiedCard), findsOneWidget);
      expect(find.byType(DiscoveryImagePanel), findsOneWidget);
    });

    testWidgets('landscape rotates without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpView(tester, [_profile('a'), _profile('b')]);

      expect(tester.takeException(), isNull);
      expect(find.byType(DiscoveryImagePanel), findsOneWidget);
    });
  });

  group('floating overlay icons', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
    });

    setUp(() async => sl.reset());

    testWidgets('both icons render ON the photo, not in a title bar', (
      tester,
    ) async {
      await _pumpView(tester, [_profile('a')]);

      // The screen-level DiscoveryTopBar (and its "استكشاف" title) is gone.
      expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

      final photo = tester.getRect(find.byType(DiscoveryImagePanel));
      for (final icon in [Icons.notifications_outlined, Icons.tune_rounded]) {
        expect(photo.contains(tester.getCenter(find.byIcon(icon))), isTrue);
      }
    });

    testWidgets('the filter button is live, not the old inert placeholder', (
      tester,
    ) async {
      await _pumpView(tester, [_profile('a')]);

      final inkWell = tester.widget<InkWell>(
        find
            .ancestor(
              of: find.byIcon(Icons.tune_rounded),
              matching: find.byType(InkWell),
            )
            .first,
      );
      expect(inkWell.onTap, isNotNull);
    });

    testWidgets('RTL puts the bell on the RIGHT and the filter on the LEFT', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpView(tester, [_profile('a')]);

      final bell = tester.getCenter(find.byIcon(Icons.notifications_outlined));
      final filter = tester.getCenter(find.byIcon(Icons.tune_rounded));
      expect(bell.dx, greaterThan(200));
      expect(filter.dx, lessThan(200));
    });

    testWidgets('LTR mirrors them', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpView(tester, [_profile('a')], direction: TextDirection.ltr);

      final bell = tester.getCenter(find.byIcon(Icons.notifications_outlined));
      final filter = tester.getCenter(find.byIcon(Icons.tune_rounded));
      expect(bell.dx, lessThan(200));
      expect(filter.dx, greaterThan(200));
    });
  });

  group('scroll reveals the full profile inline', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
    });

    setUp(() async => sl.reset());

    testWidgets('the merged body is part of the same scroll', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpView(tester, [_profile('a')]);

      // skipOffstage: false — at offset 0 the body sits past the cache
      // extent and is never laid out, which is exactly the D4 guarantee. It
      // is still ONE scrollable, not a second route.
      expect(
        find.byType(DiscoveryMergedProfileBody, skipOffstage: false),
        findsOneWidget,
      );
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('the card hydrates by id as soon as it becomes current', (
      tester,
    ) async {
      // Fired on becoming current, NOT on scroll — so the sections are already
      // there by the time the user reaches them.
      final repo = await _pumpView(tester, [_profile('a')]);

      expect(repo.requested, ['a']);
    });

    testWidgets('scrolling down brings the hydrated Q&A fully on screen', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpView(tester, [_profile('a')]);

      // The section starts as a small continuation cue at the fold.
      final before = tester.getRect(find.byType(QaDefaultSection));
      expect(before.top, lessThan(800));
      expect(before.bottom, greaterThan(800));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
      await tester.pumpAndSettle();

      // Fully on screen now, in the SAME route — no navigation happened.
      final after = tester.getRect(find.byType(QaDefaultSection));
      expect(after.top, greaterThanOrEqualTo(0));
      expect(after.bottom, lessThanOrEqualTo(800));
      expect(find.text('الديانة'), findsOneWidget);
    });

    testWidgets('the scroll survives the swipe gate closing under it', (
      tester,
    ) async {
      // Regression: the gate used to swap the swipe GestureDetector out of the
      // tree the moment the scroll left the top. That tore down its render
      // object mid-pointer, cancelling the arena entry — so the very scroll
      // that closed the gate died on its first frame and the page never moved.
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpView(tester, [_profile('a')]);
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      expect(position.maxScrollExtent, greaterThan(0));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
      await tester.pumpAndSettle();

      expect(position.pixels, position.maxScrollExtent);
    });

    testWidgets('at the top a horizontal swipe still ejects the card', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpView(tester, [_profile('a'), _profile('b')]);
      expect(find.text('Name-a 25'), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(-350, 0));
      await tester.pumpAndSettle();

      expect(find.text('Name-b 25'), findsOneWidget);
    });

    testWidgets('scrolled down, a horizontal drag does NOT eject the card', (
      tester,
    ) async {
      // The other half of the gate: ejecting the card out from under someone
      // mid-read is unrecoverable, and a near-horizontal drag while reading is
      // far more likely to be a clumsy scroll than a deliberate swipe. The
      // action buttons stay live, so nothing becomes unreachable.
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpView(tester, [_profile('a'), _profile('b')]);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(CustomScrollView), const Offset(-350, 0));
      await tester.pumpAndSettle();

      expect(find.text('Name-a 25'), findsOneWidget);
      expect(find.text('Name-b 25'), findsNothing);
    });

    testWidgets('a failed hydrate degrades to the deck payload, silently', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpView(tester, [_profile('a')], hydrationFails: true);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
      await tester.pumpAndSettle();

      // No sections, but the card is intact and nothing threw — like / skip /
      // undo must never be blocked by a hydration failure.
      expect(find.byType(QaDefaultSection), findsNothing);
      expect(find.byType(DiscoveryImagePanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the fold sits after نبذة عني (D4)', () {
    // Measured with a SHORT نبذة. The surplus these tests are about only
    // exists while photo + نبذة fit inside one viewport; a long one legitimately
    // fills the screen on its own and pushes the sections down by its own
    // height, which is the documented degradation, not a regression.
    Future<void> pumpShort(WidgetTester tester) =>
        _pumpView(tester, [_profile('a')], fullAboutMe: kShortAboutMeBody);

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
    });

    setUp(() async => sl.reset());

    testWidgets('نبذة عني is fully visible on first open', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpShort(tester);

      // Not clipped by the action buttons, not pushed off-screen.
      final intro = tester.getRect(find.byType(DiscoveryProfileIntroSheet));
      expect(intro.top, greaterThan(0));
      expect(intro.bottom, lessThanOrEqualTo(800));
      expect(find.text(kShortAboutMeBody), findsOneWidget);
    });

    testWidgets('the next profile section peeks above the fold', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpShort(tester);

      // A deliberate teaser of the continuation is visible without clipping
      // the complete نبذة عني content above it.
      final body = tester.getRect(find.byType(DiscoveryMergedProfileBody));
      expect(find.byType(QaDefaultSection), findsOneWidget);
      expect(body.top, lessThan(800));
      expect(body.bottom, greaterThan(800));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.byType(QaDefaultSection), findsOneWidget);
    });

    testWidgets('at rest the buttons sit over empty paper, not over text', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpShort(tester);

      // Photo + نبذة عني are far shorter than a screen, and the first
      // screenful is held to a full viewport, so the surplus lands under the
      // chips — exactly where the action cluster floats.
      final photo = tester.getRect(find.byType(DiscoveryImagePanel));
      final intro = tester.getRect(find.byType(DiscoveryProfileIntroSheet));
      const visible = 800 - kTopInset;
      expect(photo.height + intro.height, lessThan(visible));
      expect(
        intro.bottom,
        lessThan(tester.getRect(find.byType(DiscoveryActionBar)).top),
      );
    });

    testWidgets('the gap collapses instead of travelling with the scroll', (
      tester,
    ) async {
      // It used to be a fixed viewport-sized spacer, so the blank simply moved
      // down the page with the content and نبذة عن شريك الحياة stayed a screen
      // away no matter how far you scrolled.
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpShort(tester);

      final photoBefore = tester.getRect(find.byType(DiscoveryImagePanel)).top;
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -120));
      await tester.pump();

      // Whatever the gesture's touch slop actually delivered:
      final scrolled =
          photoBefore - tester.getRect(find.byType(DiscoveryImagePanel)).top;
      expect(scrolled, greaterThan(0));

      // The sections rise faster than the finger — that is the gap closing.
      final body = tester.getRect(find.byType(DiscoveryMergedProfileBody));
      expect(800 - body.top, greaterThan(scrolled * 2));
    });

    testWidgets('once scrolled, the sections dock flush under the chips', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpShort(tester);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      // No dead space left: the only distance between the intro sheet and the
      // sections is the overlap the sheet is deliberately lifted by.
      final intro = tester.getRect(find.byType(DiscoveryProfileIntroSheet));
      final body = tester.getRect(find.byType(DiscoveryMergedProfileBody));
      expect(
        body.top - intro.bottom,
        closeTo(DiscoveryMergedProfileBody.sheetOverlap, 1),
      );
    });
  });

  group('نبذة عني upgrades from preview to the full paragraph', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
    });

    setUp(() async => sl.reset());

    testWidgets('the hydrated text replaces the deck preview', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpView(tester, [_profile('a')]);

      // The deck's version was being left on screen, ellipsised, even though
      // the by-id profile with the whole paragraph had already arrived.
      expect(find.text(kFullAboutMeBody), findsOneWidget);
      expect(find.text(kAboutMeBody), findsNothing);
    });

    testWidgets('it runs to as many lines as it needs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpView(tester, [_profile('a')]);

      final text = tester.widget<Text>(find.text(kFullAboutMeBody));
      expect(text.maxLines, isNull);
      // The paragraph was collapsing to ONE line: an ellipsis with a null
      // maxLines is applied to the first line that outgrows the width, not
      // after some unlimited number of them.
      expect(text.overflow, isNot(TextOverflow.ellipsis));

      final painter = tester.renderObject<RenderParagraph>(
        find.text(kFullAboutMeBody),
      );
      expect(painter.size.height, greaterThan(painter.preferredLineHeight * 2));
    });

    testWidgets('a failed hydrate still shows the deck preview', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpView(tester, [_profile('a')], hydrationFails: true);

      expect(find.text(kAboutMeBody), findsOneWidget);
    });
  });

  group('the bell dot follows the unread state', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
    });

    setUp(() async => sl.reset());

    testWidgets('no dot when there is nothing unread', (tester) async {
      // Regression: moving the bell onto the photo dropped the BlocBuilder and
      // pinned the dot on unconditionally, so it claimed unread mail forever.
      await _pumpView(tester, [_profile('a')]);

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byType(OverlayUnreadDot), findsNothing);
    });

    testWidgets('the dot appears when the badge reports unread', (
      tester,
    ) async {
      await _pumpView(tester, [_profile('a')]);

      (sl<NotificationBadgeCubit>() as _FakeNotificationBadgeCubit).setUnread(
        true,
      );
      await tester.pumpAndSettle();

      expect(find.byType(OverlayUnreadDot), findsOneWidget);
    });
  });

  group('the compatibility pill is a scroll reveal (R1)', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
    });

    setUp(() async => sl.reset());

    testWidgets('absent on first open — and holding no space either', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpView(tester, [_profile('a')]);

      // Reverses the earlier "show it on the hero" call: the first impression
      // is the person, not a verdict on them. And it is genuinely gone — an
      // invisible-but-reserved gap under the name read as a layout bug.
      expect(find.byType(ProfileMatchPill), findsNothing);

      final name = tester.getRect(find.text('Name-a 25'));
      final chips = tester.getRect(find.byType(DiscoveryChipsAboveImage));
      expect(chips.top - name.bottom, lessThan(QeranSpacing.s16));
    });

    testWidgets('grows in as the user scrolls into the profile', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpView(tester, [_profile('a')]);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileMatchPill), findsOneWidget);
      final name = tester.getRect(find.text('Name-a 25'));
      final pill = tester.getRect(find.byType(ProfileMatchPill));
      final chips = tester.getRect(find.byType(DiscoveryChipsAboveImage));
      // Between the two, where the standalone full profile puts it.
      expect(pill.top, greaterThanOrEqualTo(name.bottom - 1));
      expect(pill.bottom, lessThanOrEqualTo(chips.top + 1));
    });

    testWidgets('the name climbs to make room; the chips stay put', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpView(tester, [_profile('a')]);

      final photoBefore = tester.getRect(find.byType(DiscoveryImagePanel)).top;
      final nameBefore = tester.getRect(find.text('Name-a 25')).top;
      final chipsBefore = tester
          .getRect(find.byType(DiscoveryChipsAboveImage))
          .top;

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
      await tester.pumpAndSettle();

      final scrolled =
          photoBefore - tester.getRect(find.byType(DiscoveryImagePanel)).top;
      final chipsRose =
          chipsBefore -
          tester.getRect(find.byType(DiscoveryChipsAboveImage)).top;
      final nameRose = nameBefore - tester.getRect(find.text('Name-a 25')).top;

      // The chips just ride the photo…
      expect(chipsRose, closeTo(scrolled, 1));
      // …while the name climbs further still, by the room the pill now takes.
      final pill = tester.getRect(find.byType(ProfileMatchPill));
      expect(nameRose - chipsRose, greaterThan(pill.height - 1));
    });
  });

  group('the on-image chips clear the intro sheet (R2)', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
    });

    setUp(() async => sl.reset());

    testWidgets('the sheet does not slice through the job / nationality row', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpView(tester, [_profile('a')]);

      // The sheet is lifted 24dp over the photo's bottom edge while the chips
      // sat only 20dp above it — a 4dp collision, plus zero breathing room.
      final chips = tester.getRect(find.byType(DiscoveryChipsAboveImage));
      final sheet = tester.getRect(find.byType(DiscoveryProfileIntroSheet));
      expect(chips.bottom, lessThanOrEqualTo(sheet.top));
      expect(sheet.top - chips.bottom, greaterThanOrEqualTo(12));
    });
  });

  group('the action cluster spreads toward the screen edges (R5)', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
    });

    setUp(() async => sl.reset());

    testWidgets('outer buttons sit well inside the old 48dp inset', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpView(tester, [_profile('a')]);

      // 32 (positioned) + 16 (zone padding) used to leave the buttons huddled
      // in the middle. Now 12 + 12.
      final bar = tester.getRect(find.byType(DiscoveryActionBar));
      expect(bar.left, lessThanOrEqualTo(24));
      expect(bar.right, greaterThanOrEqualTo(400 - 24));
    });
  });

  group('action backdrop is scroll-conditional (D6)', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
    });

    setUp(() async => sl.reset());

    double frostOpacity(WidgetTester tester) => tester
        .widget<DiscoveryFrostedActionZone>(
          find.byType(DiscoveryFrostedActionZone),
        )
        .opacity;

    testWidgets('no card at all at the top', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpView(tester, [_profile('a')]);

      // The buttons float over the empty spacer — a card there is pure
      // decoration, and the old always-on paper strip read as a white bar.
      expect(frostOpacity(tester), 0);
    });

    testWidgets('fades in once content is behind the buttons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpView(tester, [_profile('a')]);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(frostOpacity(tester), 1);
    });

    testWidgets('it is a ramp, not a switch', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpView(tester, [_profile('a')]);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -40));
      await tester.pump();

      final mid = frostOpacity(tester);
      expect(mid, greaterThan(0));
      expect(mid, lessThan(1));
    });
  });
}
