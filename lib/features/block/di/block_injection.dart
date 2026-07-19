import 'package:qeran/core/di/injection_container.dart';

import '../data/datasources/block_remote_datasource.dart';
import '../data/repositories/block_repository_impl.dart';
import '../domain/repositories/block_repository.dart';
import '../domain/usecases/block_user_usecase.dart';
import '../domain/usecases/get_blocked_users_usecase.dart';
import '../domain/usecases/unblock_user_usecase.dart';
import '../presentation/blocs/block_action_cubit.dart';
import '../presentation/blocs/blocked_list_cubit.dart';

/// UGC safety — user blocking (block / unblock / list). JWT-gated; full teardown
/// is server-side, the client removes the target from live views.
void initBlockDependencies() {
  sl.registerLazySingleton<BlockRemoteDataSource>(
    () => BlockRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<BlockRepository>(
    () => BlockRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => BlockUserUseCase(sl()));
  sl.registerLazySingleton(() => UnblockUserUseCase(sl()));
  sl.registerLazySingleton(() => GetBlockedUsersUseCase(sl()));
  // Screen-scoped cubits.
  sl.registerFactory(() => BlockActionCubit(blockUser: sl()));
  sl.registerFactory(() => BlockedListCubit(getBlocked: sl(), unblock: sl()));
}
