import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/connectivity/connectivity_cubit.dart';
import 'package:qeran/core/design_system/widgets/qeran_error_state.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/services/connectivity_service.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_page.dart';
import 'package:qeran/features/discovery/domain/entities/like_outcome.dart';
import 'package:qeran/features/discovery/domain/usecases/fetch_discovery_page_usecase.dart';
import 'package:qeran/features/discovery/domain/usecases/like_profile_usecase.dart';
import 'package:qeran/features/discovery/domain/usecases/pass_profile_usecase.dart';
import 'package:qeran/features/discovery/domain/usecases/reset_skipped_profiles_usecase.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_cubit.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_hydration_cubit.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_action_bar.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_card_skeleton.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_view.dart';
import 'package:qeran/features/profile/domain/repositories/profile_repository.dart';
import 'package:qeran/features/profile/domain/usecases/get_profile_by_id_usecase.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A failed PREFETCH used to be invisible and unbounded.
///
/// The deck-exhausted branch returns a skeleton and schedules `ensurePrefetch`
/// on every build. `_prefetch`'s failure path clears `isPrefetching` — so each
/// rebuild satisfied `hasMore && !isPrefetching` and fired another request,
/// forever, behind a skeleton that never changed. `prefetchError` and
/// `retryPrefetch` existed on the cubit and were read by nobody.
///
/// These pin the error surface, the retry wiring, and — the one that matters —
/// that the view stops asking once the failure is on screen.
///
/// The stub loader resolves nothing, so translation returns the key itself and
/// the assertions read as key identity rather than as copy.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

/// Page 1 lands empty while reporting a second page — the cold-start shape of
/// this bug: `isEmpty && hasMore` is true before the user touches anything.
/// Every later page fails, which is what drives `prefetchError`.
class _FakeFetch implements FetchDiscoveryPageUseCase {
  final List<int> requestedPages = [];

  @override
  Future<Either<Failure, DiscoveryPage>> call({
    int page = 1,
    int pageSize = 10,
    Map<String, String>? filterParams,
  }) async {
    requestedPages.add(page);
    if (page == 1) {
      return const Right(
        DiscoveryPage(
          profiles: [],
          pageNumber: 1,
          pageSize: 10,
          totalCount: 0,
          totalPages: 2,
        ),
      );
    }
    return const Left(ServerFailure(message: LocaleKeys.errors_generic));
  }
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

class _FakeReset implements ResetSkippedProfilesUseCase {
  @override
  Future<Either<Failure, int>> call() async => const Right(0);
}

/// The deck never carries a profile here, so nothing is ever hydrated.
class _FakeProfileRepository extends Fake implements ProfileRepository {}

class _FakeConnectivityService implements ConnectivityService {
  @override
  Future<bool> get isOnline async => true;
  @override
  Stream<bool> get onStatusChange => const Stream<bool>.empty();
}

/// Frame-stepped rather than settled: the skeleton shimmers, so `pumpAndSettle`
/// would spin until the timeout on any frame that still shows one.
Future<void> _advance(WidgetTester tester, {int frames = 8}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<_FakeFetch> _pumpView(WidgetTester tester) async {
  final fetch = _FakeFetch();
  sl.registerFactory<DiscoveryCubit>(
    () => DiscoveryCubit(
      fetchPage: fetch,
      likeProfile: _FakeLike(),
      passProfile: _FakePass(),
      resetSkipped: _FakeReset(),
    ),
  );
  sl.registerFactory<DiscoveryHydrationCubit>(
    () => DiscoveryHydrationCubit(
      getProfileById: GetProfileByIdUseCase(_FakeProfileRepository()),
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
          home: BlocProvider<ConnectivityCubit>(
            create: (_) =>
                ConnectivityCubit(service: _FakeConnectivityService()),
            child: const Scaffold(body: DiscoveryView()),
          ),
        ),
      ),
    ),
  );
  await _advance(tester);
  return fetch;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() async => sl.reset());

  testWidgets('a failed prefetch surfaces the error instead of the skeleton', (
    tester,
  ) async {
    await _pumpView(tester);

    expect(find.byType(QeranErrorState), findsOneWidget);
    expect(find.text(LocaleKeys.discovery_prefetch_failed), findsOneWidget);
    expect(find.text(LocaleKeys.discovery_error_retry), findsOneWidget);
    expect(find.byType(DiscoveryCardSkeleton), findsNothing);
  });

  testWidgets('the retry action asks for the failed page again', (
    tester,
  ) async {
    final fetch = await _pumpView(tester);
    final before = fetch.requestedPages.length;

    await tester.tap(find.text(LocaleKeys.discovery_error_retry));
    await _advance(tester);

    expect(fetch.requestedPages.length, before + 1);
    expect(fetch.requestedPages.last, 2);
  });

  // The regression this file exists for: before the error branch, every
  // rebuild re-scheduled `ensurePrefetch` and fired another request behind an
  // unchanging skeleton. Page 1 plus ONE failed page 2 is the whole budget.
  testWidgets('the view stops requesting while the error is on screen', (
    tester,
  ) async {
    final fetch = await _pumpView(tester);

    await _advance(tester, frames: 40);

    expect(fetch.requestedPages, [1, 2]);
  });

  // `_isFullScreenReplacement` keys off `!hasMore`, which is FALSE here — the
  // page the prefetch failed on still exists. Without the prefetchError clause
  // the like / pass / undo cluster floats over the error with its controls
  // dead (`current` is null) and its frosted zone over the retry button.
  testWidgets('the action cluster does not float over the error', (
    tester,
  ) async {
    await _pumpView(tester);

    expect(find.byType(DiscoveryActionBar), findsNothing);
  });
}
