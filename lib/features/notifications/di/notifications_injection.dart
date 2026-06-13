import 'package:qeran/core/di/injection_container.dart';

import '../data/datasources/notifications_remote_datasource.dart';
import '../data/repositories/notifications_repository_impl.dart';
import '../domain/repositories/notifications_repository.dart';
import '../domain/usecases/get_notifications_count_usecase.dart';
import '../domain/usecases/get_notifications_usecase.dart';
import '../presentation/blocs/notifications_cubit.dart';

/// User-app notifications (shared inbox `GET /api/notifications`). The unread
/// badge (count usecase) is wired but deferred — no UI consumes it yet.
void initNotificationsDependencies() {
  sl.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => GetNotificationsCountUseCase(sl()));
  // One inbox cubit per screen mount.
  sl.registerFactory(() => NotificationsCubit(getNotifications: sl()));
}
