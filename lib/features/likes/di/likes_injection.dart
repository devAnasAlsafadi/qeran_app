import 'package:qeran/core/di/injection_container.dart';

import '../data/datasources/likes_remote_datasource.dart';
import '../data/datasources/matches_remote_datasource.dart';
import '../data/repositories/likes_repository_impl.dart';
import '../data/repositories/matches_repository_impl.dart';
import '../domain/repositories/likes_repository.dart';
import '../domain/repositories/matches_repository.dart';
import '../domain/usecases/accept_like_usecase.dart';
import '../domain/usecases/accept_photo_exchange_usecase.dart';
import '../domain/usecases/get_incoming_likes_usecase.dart';
import '../domain/usecases/get_matches_usecase.dart';
import '../domain/usecases/get_outgoing_likes_usecase.dart';
import '../domain/usecases/reject_like_usecase.dart';
import '../domain/usecases/reject_photo_exchange_usecase.dart';
import '../domain/usecases/request_photo_exchange_usecase.dart';
import '../presentation/blocs/likes_cubit.dart';

void initLikesDependencies() {
  //! DataSources
  sl.registerLazySingleton<LikesRemoteDataSource>(
    () => LikesRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<MatchesRemoteDataSource>(
    () => MatchesRemoteDataSourceImpl(apiConsumer: sl()),
  );

  //! Repositories
  sl.registerLazySingleton<LikesRepository>(
    () => LikesRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<MatchesRepository>(
    () => MatchesRepositoryImpl(sl()),
  );

  //! UseCases — likes
  sl.registerLazySingleton(() => GetIncomingLikesUseCase(sl()));
  sl.registerLazySingleton(() => GetOutgoingLikesUseCase(sl()));
  sl.registerLazySingleton(() => AcceptLikeUseCase(sl()));
  sl.registerLazySingleton(() => RejectLikeUseCase(sl()));

  //! UseCases — matches / photo exchange
  sl.registerLazySingleton(() => GetMatchesUseCase(sl()));
  sl.registerLazySingleton(() => RequestPhotoExchangeUseCase(sl()));
  sl.registerLazySingleton(() => AcceptPhotoExchangeUseCase(sl()));
  sl.registerLazySingleton(() => RejectPhotoExchangeUseCase(sl()));

  //! Cubits (screen-scoped) — fresh instance per LikesScreen mount so
  //  pull-to-refresh / tab state don't leak between sessions.
  sl.registerFactory(
    () => LikesCubit(
      getIncoming: sl(),
      getOutgoing: sl(),
      acceptLike: sl(),
      rejectLike: sl(),
      getMatches: sl(),
      requestPhotoExchange: sl(),
      acceptPhotoExchange: sl(),
      rejectPhotoExchange: sl(),
    ),
  );
}
