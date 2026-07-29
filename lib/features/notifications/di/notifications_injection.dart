import 'package:qeran/core/di/injection_container.dart';

import '../data/datasources/notifications_remote_datasource.dart';
import '../data/repositories/notifications_repository_impl.dart';
import '../domain/repositories/notifications_repository.dart';
import '../domain/usecases/get_notifications_usecase.dart';
import '../presentation/blocs/notification_badge_cubit.dart';
import '../presentation/blocs/notification_read_cubit.dart';
import '../presentation/blocs/notifications_cubit.dart';

/// User-app notifications (shared inbox `GET /api/notifications`). The unread
/// badge keys off the newest notification id (local lastSeenId heuristic).
void initNotificationsDependencies() {
  sl.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  // One inbox cubit per screen mount.
  sl.registerFactory(() => NotificationsCubit(getNotifications: sl()));
  // App-wide unread-badge source (lazy singleton, shared by the discovery bell
  // + the inbox screen). Local lastSeenId heuristic — no backend read-state.
  sl.registerLazySingleton(
    () => NotificationBadgeCubit(getNotifications: sl(), prefs: sl()),
  );
  // Local read-state for the inbox rows (separate from the bell's "seen"
  // heuristic). Singleton so the styling survives leaving and re-entering.
  sl.registerLazySingleton(() => NotificationReadCubit(prefs: sl()));
}
