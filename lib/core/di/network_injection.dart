import '../api/api_consumer.dart';
import '../api/http_consumer.dart';
import '../api/http_progress_uploader.dart';
import '../api/http_request_context.dart';
import '../api/progress_uploader.dart';
import '../services/connectivity_service.dart';
import '../services/connectivity_service_impl.dart';
import '../session/session_expiry.dart';
import 'injection_container.dart';

/// The connectivity signal, our API client and the progress uploader. Needs
/// the `http.Client`, storage and language already registered.
void initNetworkDependencies() {
  // Connectivity signal — registered before ApiConsumer, which consumes it
  // for the offline pre-flight.
  sl.registerLazySingleton<ConnectivityService>(
    () => ConnectivityServiceImpl(),
  );
  // Every 401 to our Bearer, for the session to act on (C4).
  sl.registerLazySingleton(SessionExpiry.new);
  sl.registerLazySingleton<ApiConsumer>(
    () => HttpConsumer(
      client: sl(),
      storage: sl(),
      languageService: sl(),
      connectivity: sl(),
      sessionExpiry: sl(),
    ),
  );
  sl.registerLazySingleton<ProgressUploader>(
    () => HttpProgressUploader(
      client: sl(),
      context: HttpRequestContext(
        storage: sl(),
        languageService: sl(),
        connectivity: sl(),
        sessionExpiry: sl(),
      ),
    ),
  );
}
