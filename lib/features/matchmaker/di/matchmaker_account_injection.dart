import 'package:qeran/core/di/injection_container.dart';

import '../account/data/datasources/matchmaker_account_remote_datasource.dart';
import '../account/data/repositories/matchmaker_account_repository_impl.dart';
import '../account/domain/repositories/matchmaker_account_repository.dart';
import '../account/domain/usecases/change_password_usecase.dart';
import '../account/domain/usecases/deactivate_account_usecase.dart';
import '../account/domain/usecases/delete_matchmaker_account_usecase.dart';
import '../account/domain/usecases/get_me_usecase.dart';
import '../account/domain/usecases/update_name_usecase.dart';
import '../account/domain/usecases/upload_account_photo_usecase.dart';
import '../account/presentation/blocs/matchmaker_account_cubit.dart';
import '../account/presentation/blocs/matchmaker_delete_account_cubit.dart';
import '../affiliate/data/datasources/affiliate_remote_datasource.dart';
import '../affiliate/data/repositories/affiliate_repository_impl.dart';
import '../affiliate/domain/repositories/affiliate_repository.dart';
import '../affiliate/domain/usecases/get_affiliate_commissions_usecase.dart';
import '../affiliate/domain/usecases/get_affiliate_summary_usecase.dart';
import '../affiliate/presentation/blocs/affiliate_commissions_cubit.dart';
import '../affiliate/presentation/blocs/affiliate_summary_cubit.dart';
import '../notifications/data/datasources/matchmaker_notifications_remote_datasource.dart';
import '../notifications/data/repositories/matchmaker_notifications_repository_impl.dart';
import '../notifications/domain/repositories/matchmaker_notifications_repository.dart';
import '../notifications/domain/usecases/get_notifications_usecase.dart';
import '../notifications/presentation/blocs/matchmaker_notification_read_cubit.dart';
import '../notifications/presentation/blocs/matchmaker_notifications_cubit.dart';

/// Her inbox, her account, and her affiliate summary.
/// Called by [initMatchmakerDependencies].
void initMatchmakerAccountDependencies() {
  //! ── F5 · Notifications (shared inbox + local unread badge) ───────
  sl.registerLazySingleton<MatchmakerNotificationsRemoteDataSource>(
    () => MatchmakerNotificationsRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<MatchmakerNotificationsRepository>(
    () => MatchmakerNotificationsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  // One inbox cubit per screen mount.
  sl.registerFactory(
    () => MatchmakerNotificationsCubit(getNotifications: sl()),
  );
  // FACTORY, deliberately: the watermark it exposes is frozen at mount, so a
  // fresh instance per visit is what makes the next visit start clean.
  sl.registerFactory(() => MatchmakerNotificationReadCubit(prefs: sl()));

  //! ── S1a · Account (matchmaker/me) ────────────────────────────────
  // Data/domain only here; the MatchmakerAccountCubit (+ its screen wiring)
  // is registered in S1b once the cubit class exists.
  sl.registerLazySingleton<MatchmakerAccountRemoteDataSource>(
    () => MatchmakerAccountRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<MatchmakerAccountRepository>(
    () => MatchmakerAccountRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetMeUseCase(sl()));
  sl.registerLazySingleton(() => UpdateNameUseCase(sl()));
  sl.registerLazySingleton(() => UploadAccountPhotoUseCase(sl()));
  sl.registerLazySingleton(() => DeactivateAccountUseCase(sl()));
  sl.registerLazySingleton(() => DeleteMatchmakerAccountUseCase(sl()));
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));
  // One cubit per account-screen mount (S1b/S1c).
  sl.registerFactory(
    () => MatchmakerAccountCubit(
      getMe: sl(),
      updateName: sl(),
      uploadPhoto: sl(),
      deactivate: sl(),
      changePassword: sl(),
    ),
  );
  // Permanent account deletion (mirrors the user delete cubit).
  sl.registerFactory(
    () => MatchmakerDeleteAccountCubit(
      deleteAccount: sl(),
      deviceBootstrap: sl(),
      session: sl(),
    ),
  );

  //! ── Affiliate · Dashboard summary ────────────────────────────────
  sl.registerLazySingleton<AffiliateRemoteDataSource>(
    () => AffiliateRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<AffiliateRepository>(
    () => AffiliateRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetAffiliateSummaryUseCase(sl()));
  sl.registerLazySingleton(() => GetAffiliateCommissionsUseCase(sl()));
  // One cubit per affiliate-screen mount.
  sl.registerFactory(() => AffiliateSummaryCubit(getSummary: sl()));
  sl.registerFactory(() => AffiliateCommissionsCubit(getCommissions: sl()));
}
