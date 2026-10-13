import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/connectivity/connectivity_cubit.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/services/connectivity_service.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/chat/domain/entities/my_matchmaker_outcome.dart';
import 'package:qeran/features/chat/domain/repositories/chat_repository.dart';
import 'package:qeran/features/chat/domain/usecases/get_my_matchmaker_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/share_profile_usecase.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_page.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_profile.dart';
import 'package:qeran/features/discovery/domain/entities/like_outcome.dart';
import 'package:qeran/features/discovery/domain/usecases/fetch_discovery_page_usecase.dart';
import 'package:qeran/features/discovery/domain/usecases/like_profile_usecase.dart';
import 'package:qeran/features/discovery/domain/usecases/pass_profile_usecase.dart';
import 'package:qeran/features/discovery/domain/usecases/reset_skipped_profiles_usecase.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_cubit.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_hydration_cubit.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_card.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_view.dart';
import 'package:qeran/features/profile/domain/entities/profile_entry_source.dart';
import 'package:qeran/features/profile/presentation/full_profile_details_args.dart';
import 'package:qeran/features/profile/domain/entities/profile_fetch_outcome.dart';
import 'package:qeran/features/profile/domain/repositories/profile_repository.dart';
import 'package:qeran/features/profile/domain/usecases/get_profile_by_id_usecase.dart';
import 'package:qeran/features/profile/presentation/blocs/share_with_matchmaker/share_with_matchmaker_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys render as themselves.
class _Keys extends AssetLoader {
  const _Keys();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

DiscoveryProfile _p(String id) => DiscoveryProfile(
  id: id,
  name: 'Name-$id',
  age: 25,
  images: const [],
  matchingScore: 0,
  placements: const [],
);

class _Fetch implements FetchDiscoveryPageUseCase {
  @override
  Future<Either<Failure, DiscoveryPage>> call({
    int page = 1,
    int pageSize = 10,
    Map<String, String>? filterParams,
  }) async => Right(
    DiscoveryPage(
      profiles: [_p('a'), _p('b')],
      pageNumber: 1,
      pageSize: 10,
      totalCount: 2,
      totalPages: 1,
    ),
  );
}

class _Like implements LikeProfileUseCase {
  @override
  Future<Either<Failure, LikeOutcome>> call(String id) async =>
      const Right(LikeAccepted(likeId: '1'));
}

class _Pass implements PassProfileUseCase {
  @override
  Future<Either<Failure, Unit>> call(String id) async => const Right(unit);
}

class _Reset implements ResetSkippedProfilesUseCase {
  @override
  Future<Either<Failure, int>> call() async => const Right(0);
}

class _Profiles extends Fake implements ProfileRepository {
  @override
  Future<Either<Failure, ProfileFetchOutcome>> getProfileById(
    String id,
  ) async => const Left(ServerFailure(message: 'errors.generic'));
}

class _Chat extends Fake implements ChatRepository {
  @override
  Future<Either<Failure, MyMatchmakerOutcome>> getMyMatchmaker() async =>
      const Left(ServerFailure(message: 'errors.generic'));
}

class _Online implements ConnectivityService {
  @override
  Future<bool> get isOnline async => true;
  @override
  Stream<bool> get onStatusChange => const Stream<bool>.empty();
}

/// Run 7 (Anas's hand check): the Suggestions card carries no ⋮. A tap on its
/// photo or its name opens the full profile, whose ⋮ reports and blocks
/// (Apple 1.2, one tap away). A block there closes it with the member's id,
/// and the card leaves the deck: the next member, same screen, no reload.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() async {
    await sl.reset();
    sl.registerFactory<DiscoveryCubit>(
      () => DiscoveryCubit(
        fetchPage: _Fetch(),
        likeProfile: _Like(),
        passProfile: _Pass(),
        resetSkipped: _Reset(),
      ),
    );
    sl.registerFactory<DiscoveryHydrationCubit>(
      () => DiscoveryHydrationCubit(
        getProfileById: GetProfileByIdUseCase(_Profiles()),
      ),
    );
    sl.registerFactory<ShareWithMatchmakerCubit>(
      () => ShareWithMatchmakerCubit(
        getMyMatchmaker: GetMyMatchmakerUseCase(_Chat()),
        shareProfile: ShareProfileUseCase(_Chat()),
      ),
    );
  });

  tearDown(AppSnackBar.debugReset);

  /// Pumps Suggestions; the full profile is a stand-in that records what it
  /// was opened with.
  Future<List<FullProfileDetailsArgs>> pump(WidgetTester tester) async {
    final opened = <FullProfileDetailsArgs>[];
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/translations',
        assetLoader: const _Keys(),
        child: Builder(
          builder: (ctx) => MaterialApp(
            locale: ctx.locale,
            supportedLocales: ctx.supportedLocales,
            localizationsDelegates: ctx.localizationDelegates,
            builder: (_, child) => AppSnackBarHost(child: child!),
            onGenerateRoute: (settings) {
              if (settings.name != RouteNames.fullProfileDetails) return null;
              opened.add(settings.arguments! as FullProfileDetailsArgs);
              return MaterialPageRoute<Object?>(
                settings: settings,
                builder: (_) => const Scaffold(body: Text('full profile')),
              );
            },
            home: BlocProvider<ConnectivityCubit>(
              create: (_) => ConnectivityCubit(service: _Online()),
              child: const Scaffold(body: DiscoveryView()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return opened;
  }

  Future<void> closeProfile(WidgetTester tester, [Object? result]) async {
    tester.state<NavigatorState>(find.byType(Navigator)).pop(result);
    await tester.pumpAndSettle();
  }

  testWidgets('the card has no ⋮', (tester) async {
    await pump(tester);
    expect(find.text('Name-a 25'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('a tap on the photo opens the full profile', (tester) async {
    final opened = await pump(tester);
    await tester.tap(find.byType(DiscoveryImagePanel));
    await tester.pumpAndSettle();
    expect(find.text('full profile'), findsOneWidget);
    expect(opened.single.userId, 'a');
    expect(opened.single.entry, ProfileEntrySource.discovery);
    expect(opened.single.initialData?.name, 'Name-a');
  });

  testWidgets('so does a tap on the name', (tester) async {
    final opened = await pump(tester);
    await tester.tap(find.text('Name-a 25'));
    await tester.pumpAndSettle();
    expect(opened.single.userId, 'a');
  });

  testWidgets('blocked there: back on Suggestions, the next member', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Name-a 25'));
    await tester.pumpAndSettle();
    await closeProfile(tester, 'a');
    expect(find.text('Name-a 25'), findsNothing);
    expect(find.text('Name-b 25'), findsOneWidget);
    expect(find.byType(DiscoveryView), findsOneWidget);
  });

  testWidgets('closed without a block: the same member stays', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Name-a 25'));
    await tester.pumpAndSettle();
    await closeProfile(tester);
    expect(find.text('Name-a 25'), findsOneWidget);
  });
}
