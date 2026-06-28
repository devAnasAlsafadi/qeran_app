import 'package:qeran/core/di/injection_container.dart';

import '../data/datasources/support_remote_datasource.dart';
import '../data/repositories/support_repository_impl.dart';
import '../domain/repositories/support_repository.dart';
import '../domain/usecases/create_support_ticket_usecase.dart';
import '../domain/usecases/get_support_categories_usecase.dart';
import '../presentation/blocs/support_cubit.dart';

/// Help & Support — problem-type list (GET) + ticket submission (POST), both
/// JWT-gated.
void initSupportDependencies() {
  sl.registerLazySingleton<SupportRemoteDataSource>(
    () => SupportRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<SupportRepository>(
    () => SupportRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetSupportCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => CreateSupportTicketUseCase(sl()));
  // One cubit per screen mount.
  sl.registerFactory(
    () => SupportCubit(getCategories: sl(), createTicket: sl()),
  );
}
