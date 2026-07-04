import 'package:qeran/core/di/injection_container.dart';

import '../data/datasources/subscriptions_remote_datasource.dart';
import '../data/repositories/purchase_repository_impl.dart';
import '../data/repositories/subscriptions_repository_impl.dart';
import '../domain/repositories/purchase_repository.dart';
import '../domain/repositories/subscriptions_repository.dart';
import '../domain/usecases/check_premium_status_usecase.dart';
import '../domain/usecases/get_current_subscription_usecase.dart';
import '../domain/usecases/get_store_products_usecase.dart';
import '../domain/usecases/get_subscription_plans_usecase.dart';
import '../domain/usecases/purchase_package_usecase.dart';
import '../domain/usecases/restore_purchases_usecase.dart';
import '../domain/usecases/subscribe_usecase.dart';
import '../domain/usecases/validate_code_usecase.dart';
import '../presentation/blocs/current/current_subscription_cubit.dart';
import '../presentation/blocs/plans/subscription_plans_cubit.dart';
import '../presentation/blocs/purchase/package_purchase_cubit.dart';

void initSubscriptionDependencies() {
  //! DataSource
  sl.registerLazySingleton<SubscriptionsRemoteDataSource>(
    () => SubscriptionsRemoteDataSourceImpl(apiConsumer: sl()),
  );

  //! Repository
  sl.registerLazySingleton<SubscriptionsRepository>(
    () => SubscriptionsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<PurchaseRepository>(
    () => PurchaseRepositoryImpl(sl()),
  );

  //! UseCases
  sl.registerLazySingleton(() => GetSubscriptionPlansUseCase(sl()));
  sl.registerLazySingleton(() => GetStoreProductsUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentSubscriptionUseCase(sl()));
  sl.registerLazySingleton(() => SubscribeUseCase(sl()));
  sl.registerLazySingleton(() => ValidateCodeUseCase(sl()));
  sl.registerLazySingleton(() => PurchasePackageUseCase(sl()));
  sl.registerLazySingleton(() => RestorePurchasesUseCase(sl()));
  sl.registerLazySingleton(() => CheckPremiumStatusUseCase(sl()));

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
    () => SubscriptionPlansCubit(getPlans: sl(), getStoreProducts: sl()),
  );

  //! Package purchase cubit — screen-scoped factory (new instance per paywall).
  sl.registerFactory<PackagePurchaseCubit>(
    () => PackagePurchaseCubit(
      validateCode: sl(),
      purchasePackage: sl(),
      restorePurchases: sl(),
      currentSubscription: sl(),
      revenueCat: sl(),
    ),
  );
}
