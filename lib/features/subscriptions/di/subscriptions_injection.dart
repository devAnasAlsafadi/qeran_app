import 'package:qeran/core/di/injection_container.dart';

import '../data/datasources/subscriptions_remote_datasource.dart';
import '../data/repositories/subscriptions_repository_impl.dart';
import '../domain/repositories/subscriptions_repository.dart';
import '../domain/usecases/get_current_subscription_usecase.dart';
import '../domain/usecases/get_subscription_plans_usecase.dart';
import '../domain/usecases/subscribe_usecase.dart';
import '../domain/usecases/validate_code_usecase.dart';
import '../presentation/blocs/current/current_subscription_cubit.dart';
import '../presentation/blocs/plans/subscription_plans_cubit.dart';

void initSubscriptionDependencies() {
  //! DataSource
  sl.registerLazySingleton<SubscriptionsRemoteDataSource>(
    () => SubscriptionsRemoteDataSourceImpl(apiConsumer: sl()),
  );

  //! Repository
  sl.registerLazySingleton<SubscriptionsRepository>(
    () => SubscriptionsRepositoryImpl(sl()),
  );

  //! UseCases
  sl.registerLazySingleton(() => GetSubscriptionPlansUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentSubscriptionUseCase(sl()));
  sl.registerLazySingleton(() => SubscribeUseCase(sl()));
  sl.registerLazySingleton(() => ValidateCodeUseCase(sl()));

  //! Current Subscription — app-scoped lazy singleton.
  //
  // Same carve-out as `UserSessionCubit`: state must outlive any
  // single screen because /current is the SOT for paywall, profile
  // status block, and any future feature gating.
  sl.registerLazySingleton<CurrentSubscriptionCubit>(
    () => CurrentSubscriptionCubit(getCurrent: sl()),
  );

  //! Plans cubit — screen-scoped factory.
  sl.registerFactory<SubscriptionPlansCubit>(
    () => SubscriptionPlansCubit(getPlans: sl()),
  );
}
