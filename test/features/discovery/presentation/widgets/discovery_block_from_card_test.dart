import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/connectivity/connectivity_cubit.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/services/connectivity_service.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/block/presentation/blocs/block_action_cubit.dart';
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
import 'package:qeran/features/discovery/presentation/widgets/discovery_view.dart';
import 'package:qeran/features/profile/domain/entities/profile_fetch_outcome.dart';
import 'package:qeran/features/profile/domain/repositories/profile_repository.dart';
import 'package:qeran/features/profile/domain/usecases/get_profile_by_id_usecase.dart';
import 'package:qeran/features/profile/presentation/blocs/share_with_matchmaker/share_with_matchmaker_cubit.dart';
import 'package:qeran/generated/locale_keys.g.dart';
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

/// The whole Suggestions screen: blocking from a card brings the next member
/// up, on the same screen, with nothing reloaded (run 6).
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
    sl.registerFactoryParam<BlockActionCubit, BlockOrigin, void>(
      (_, _) => BlockActionCubit(
        block: (_) async => const Right<Failure, void>(null),
      ),
    );
  });

  tearDown(AppSnackBar.debugReset);

  testWidgets('blocked from the card: the next member, same screen', (
    tester,
  ) async {
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
            home: BlocProvider<ConnectivityCubit>(
              create: (_) => ConnectivityCubit(service: _Online()),
              child: const Scaffold(body: DiscoveryView()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Name-a 25'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(LocaleKeys.block_action_block));
    await tester.pumpAndSettle();
    await tester.tap(find.text(LocaleKeys.block_confirm_button));
    await tester.pumpAndSettle();

    expect(find.text('Name-a 25'), findsNothing);
    expect(find.text('Name-b 25'), findsOneWidget);
    expect(find.byType(DiscoveryView), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
