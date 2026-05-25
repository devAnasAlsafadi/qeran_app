import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';

import '../data/datasources/discovery_remote_datasource.dart';
import '../data/repositories/discovery_repository_impl.dart';
import '../domain/repositories/discovery_repository.dart';
import '../domain/usecases/fetch_discovery_page_usecase.dart';
import '../domain/usecases/get_discovery_filters_usecase.dart';
import '../domain/usecases/like_profile_usecase.dart';
import '../domain/usecases/pass_profile_usecase.dart';
import '../presentation/blocs/discovery_cubit.dart';
import '../presentation/blocs/discovery_filter_cubit.dart';

void initDiscoveryDependencies() {
  //! DataSource
  sl.registerLazySingleton<DiscoveryRemoteDataSource>(
    () => DiscoveryRemoteDataSourceImpl(apiConsumer: sl()),
  );

  //! Repository
  sl.registerLazySingleton<DiscoveryRepository>(
    () => DiscoveryRepositoryImpl(sl()),
  );

  //! UseCases
  sl.registerLazySingleton(() => FetchDiscoveryPageUseCase(sl()));
  sl.registerLazySingleton(() => LikeProfileUseCase(sl()));
  sl.registerLazySingleton(() => PassProfileUseCase(sl()));
  sl.registerLazySingleton(() => GetDiscoveryFiltersUseCase(sl()));

  //! Cubits (screen-scoped)
  // The `onLikeSuccess` callback is wired here — DiscoveryCubit stays
  // decoupled from the subscription feature, but every LikeAccepted
  // outcome refreshes the app-scoped CurrentSubscriptionCubit so the
  // Profile screen's remaining-likes counter never goes stale. The
  // refresh is fire-and-forget; it never blocks the card transition.
  sl.registerFactory(
    () => DiscoveryCubit(
      fetchPage: sl(),
      likeProfile: sl(),
      passProfile: sl(),
      onLikeSuccess: sl<CurrentSubscriptionCubit>().onActionConsumedCounter,
    ),
  );
  // Sheet-scoped. Chunk D may switch to `registerFactoryParam` to
  // seed with currently-active filters; for now the cubit opens with
  // an empty selection map.
  sl.registerFactory(
    () => DiscoveryFilterCubit(getFilters: sl()),
  );
}
