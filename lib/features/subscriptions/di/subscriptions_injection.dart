import 'package:flutter/widgets.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/services/payment_gateway.dart';

import '../data/datasources/subscriptions_remote_datasource.dart';
import '../data/repositories/subscriptions_repository_impl.dart';
import '../domain/repositories/subscriptions_repository.dart';
import '../domain/usecases/get_current_subscription_usecase.dart';
import '../domain/usecases/get_subscription_plans_usecase.dart';
import '../domain/usecases/subscribe_usecase.dart';
import '../domain/usecases/validate_discount_code_usecase.dart';
import '../infrastructure/fake_payment_gateway.dart';
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
  sl.registerLazySingleton(() => ValidateDiscountCodeUseCase(sl()));
  sl.registerLazySingleton(() => SubscribeUseCase(sl()));

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

  //! Payment gateway — dev stub for now. Uses the app-wide navigator
  //  key (`MaterialApp.navigatorKey`) so it never needs a per-screen
  //  bind/unbind dance. Swap this binding for IAP / MyFatoorah / …
  //  when production lands; nothing else changes.
  sl.registerLazySingleton<PaymentGateway>(
    () => FakePaymentGateway(navigatorKey: sl<GlobalKey<NavigatorState>>()),
  );

  //
  //  Note: `SubscriptionPurchaseCubit` is intentionally NOT registered
  //  in GetIt — it depends on a runtime-chosen `SubscriptionPricing`
  //  argument and is screen-scoped. The screen constructs it directly
  //  with its dependencies pulled from `sl<>()`. This avoids the
  //  `registerFactoryParam<..., void>` pattern (unusual, error-prone)
  //  and makes the dependency chain explicit at the call site.
}
