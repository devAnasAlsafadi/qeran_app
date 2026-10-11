import '../constants/storage_keys.dart';
import '../errors/exceptions.dart';
import '../services/connectivity_service.dart';
import '../services/language_service.dart';
import '../services/storage_service.dart';
import '../session/session_expiry.dart';

/// What every request to our own API carries, shared by `HttpConsumer` and
/// the progress uploader: the offline pre-flight and our headers. A foreign
/// origin (a video provider) gets none of it — the Bearer is ours only.
class HttpRequestContext {
  final StorageService storage;
  final LanguageService languageService;
  final ConnectivityService connectivity;

  /// Told of every 401 to our Bearer ([noteStatus]); none in a test that
  /// doesn't care.
  final SessionExpiry? sessionExpiry;

  const HttpRequestContext({
    required this.storage,
    required this.languageService,
    required this.connectivity,
    this.sessionExpiry,
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

  /// A 401 to a request that carried our Bearer means that token is no longer
  /// good (TQ11), so it is reported to [sessionExpiry]. A request without one
  /// (login, register, OTP, or one sent after sign-out) never reports, and
  /// neither does a 403: a permission error, not a session one.
  void noteStatus(int statusCode, Map<String, String> sentHeaders) {
    if (statusCode != 401) return;
    final bearer = sentHeaders['Authorization'] ?? '';
    if (!bearer.startsWith(_bearer)) return;
    final token = bearer.substring(_bearer.length);
    if (token.isNotEmpty) sessionExpiry?.report(token);
  }

  static const String _bearer = 'Bearer ';
}
