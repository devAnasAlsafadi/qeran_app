import 'package:google_sign_in/google_sign_in.dart';

/// Owns the one-time initialization required by google_sign_in v7.
///
/// Startup can warm the plugin in the background, while an early login tap
/// safely awaits the same Future instead of racing `authenticate()`.
class GoogleSignInService {
  final GoogleSignIn _client;
  Future<void>? _initialization;

  GoogleSignInService({GoogleSignIn? client})
    : _client = client ?? GoogleSignIn.instance;

  Future<void> initialize() {
    final existing = _initialization;
    if (existing != null) return existing;
    final request = _initialize();
    _initialization = request;
    return request;
  }

  Future<void> _initialize() async {
    try {
      await _client.initialize();
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<GoogleSignInAccount> authenticate() async {
    await initialize();
    return _client.authenticate();
  }

  Future<void> signOut() async {
    await initialize();
    await _client.signOut();
  }
}
