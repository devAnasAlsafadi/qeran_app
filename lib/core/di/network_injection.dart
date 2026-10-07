import '../api/api_consumer.dart';
import '../api/http_consumer.dart';
import '../services/connectivity_service.dart';
import '../services/connectivity_service_impl.dart';
import 'injection_container.dart';

/// The connectivity signal and our API client. Needs the `http.Client`,
/// storage and language already registered.
void initNetworkDependencies() {
  // Connectivity signal — registered before ApiConsumer, which consumes it
  // for the offline pre-flight.
  sl.registerLazySingleton<ConnectivityService>(
    () => ConnectivityServiceImpl(),
  );
  sl.registerLazySingleton<ApiConsumer>(
    () => HttpConsumer(
      client: sl(),
      storage: sl(),
      languageService: sl(),
      connectivity: sl(),
    ),
  );
}
