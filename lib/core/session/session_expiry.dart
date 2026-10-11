import 'dart:async';

/// Our API refused a request's Bearer with 401 (C4, TQ11): the token expired
/// or is corrupt, or the account behind it was deleted, banned or had its
/// password changed. The HTTP layer reports the token the request carried;
/// the session decides what that means for whoever is signed in now.
class SessionExpiry {
  final StreamController<String> _reports =
      StreamController<String>.broadcast();

  /// Each refused token, as it is reported.
  Stream<String> get reports => _reports.stream;

  void report(String token) => _reports.add(token);
}
