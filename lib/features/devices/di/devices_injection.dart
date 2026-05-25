import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/services/device_info_service.dart';
import 'package:qeran/core/services/language_service.dart';
import 'package:qeran/core/services/notification_service.dart';
import 'package:qeran/core/services/storage_service.dart';

import '../application/device_bootstrap_service.dart';
import '../data/datasources/device_remote_datasource.dart';
import '../data/repositories/device_repository_impl.dart';
import '../domain/repositories/device_repository.dart';
import '../domain/usecases/link_device_usecase.dart';
import '../domain/usecases/register_device_usecase.dart';

void initDevicesDependencies() {
  //! DataSources
  sl.registerLazySingleton<DeviceRemoteDataSource>(
    () => DeviceRemoteDataSourceImpl(apiConsumer: sl()),
  );

  //! Repositories
  sl.registerLazySingleton<DeviceRepository>(
    () => DeviceRepositoryImpl(sl<DeviceRemoteDataSource>()),
  );

  //! UseCases
  sl.registerLazySingleton(() => RegisterDeviceUseCase(sl<DeviceRepository>()));
  sl.registerLazySingleton(() => LinkDeviceUseCase(sl<DeviceRepository>()));

  //! Orchestrator
  sl.registerLazySingleton<DeviceBootstrapService>(
    () => DeviceBootstrapService(
      notifications: sl<NotificationService>(),
      deviceInfo: sl<DeviceInfoService>(),
      registerDevice: sl(),
      linkDevice: sl(),
      sharedPrefs: sl<SharedPrefService>(),
      secureStorage: sl<StorageService>(),
      language: sl<LanguageService>(),
    ),
  );
}
