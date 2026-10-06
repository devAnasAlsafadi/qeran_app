import '../constants/storage_keys.dart';
import '../errors/exceptions.dart';
import '../services/connectivity_service.dart';
import '../services/language_service.dart';
import '../services/storage_service.dart';

/// What every request to our own API carries, shared by `HttpConsumer` and
/// the progress uploader: the offline pre-flight and our headers. A foreign
/// origin (a video provider) gets none of it — the Bearer is ours only.
class HttpRequestContext {
  final StorageService storage;
  final LanguageService languageService;
  final ConnectivityService connectivity;

  const HttpRequestContext({
    required this.storage,
    required this.languageService,
    required this.connectivity,
  });

  /// Offline pre-flight — throws [OfflineException] BEFORE a request fires
  /// when the device reports no connectivity, so callers fast-fail instead of
  /// waiting out the timeout. Called at the top of each request's `try` so a
  /// thrown [OfflineException] is rethrown by its catch and bubbles to the
  /// repository as `OfflineFailure`.
  Future<void> ensureOnline() async {
    if (!await connectivity.isOnline) throw const OfflineException();
  }

  /// JSON, the app's language, and the Bearer when signed in.
  Future<Map<String, String>> headers() async {
    final token = await storage.get<String>(StorageKeys.token);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': languageService.currentLanguage,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
