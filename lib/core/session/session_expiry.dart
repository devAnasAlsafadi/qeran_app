import 'dart:async';

/// Our API refused a request's Bearer with 401 (C4, TQ11): the token expired
/// or is corrupt, or the account behind it was deleted, banned or had its
/// password changed. The HTTP layer reports the token the request carried;
/// the session decides what that means for whoever is signed in now.
class SessionExpiry {
  final StreamController<String> _reports =
      StreamController<String>.broadcast();

  /// Calls that replace the token, while they run ([renewing]).
  final Set<Future<void>> _renewals = {};

  /// Each refused token, as it is reported.
  Stream<String> get reports => _reports.stream;

  void report(String token) => _reports.add(token);

  /// Runs [renewal], a call that replaces the stored token (a password
  /// change): the server refuses the old token as soon as it accepts the
  /// change, so a 401 can land before the new token does. Reports are judged
  /// only once it has settled ([settled]).
  Future<T> renewing<T>(Future<T> Function() renewal) async {
    final done = Completer<void>();
    _renewals.add(done.future);
    try {
      return await renewal();
    } finally {
      _renewals.remove(done.future);
      done.complete();
    }
  }

  /// Completes once no [renewing] call is in flight.
  Future<void> settled() async {
    while (_renewals.isNotEmpty) {
      await Future.wait(_renewals.toList());
    }
  }
}
