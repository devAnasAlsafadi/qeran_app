import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_consumer.dart';
import '../api/http_consumer.dart';
import '../datasources/shared_pref_service.dart';
import '../datasources/secure_storage_service.dart';
import '../services/storage_service.dart';

final sl = GetIt.instance;

Future<void> init() async {

  //! External
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPrefs);
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => http.Client());

  //! Storage
  // SecureStorageService is the default StorageService (used for sensitive data like tokens).
  // Use sl<SharedPrefService>() explicitly for non-sensitive preferences.
  sl.registerLazySingleton<StorageService>(() => SecureStorageService(sl()));
  sl.registerLazySingleton<SharedPrefService>(() => SharedPrefService(sl()));

  //! Network
  sl.registerLazySingleton<ApiConsumer>(() => HttpConsumer(client: sl(), storage: sl()));

}