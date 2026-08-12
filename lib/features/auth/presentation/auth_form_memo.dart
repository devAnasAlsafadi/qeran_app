import 'package:qeran/core/di/injection_container.dart';

/// The app-scoped memo, or a throwaway one when the container has not been
/// booted. Widget tests that register only the blocs they need therefore get
/// an isolated instance rather than a lookup crash — and isolation between
/// tests is the behaviour they want regardless.
AuthFormMemo resolveAuthFormMemo() =>
    sl.isRegistered<AuthFormMemo>() ? sl<AuthFormMemo>() : AuthFormMemo();

/// Carries what the member has typed across a login ↔ register hop.
///
/// The two screens own their own [TextEditingController]s and are built fresh
/// on every navigation, so the fields are empty by construction when they come
/// back. This holds the values worth restoring.
///
/// IDENTIFYING FIELDS ONLY — email and display name. The password is
/// deliberately not kept: a long-lived plaintext password in memory buys a
/// small convenience for a real exposure, and the member re-typing it is the
/// correct trade for a matrimony account.
///
/// In-memory and never persisted. Cleared the moment sign-in or registration
/// succeeds, and again on sign-out.
class AuthFormMemo {
  String _email = '';
  String _displayName = '';

  String get email => _email;

  /// The username shown to other members. Register-only — the login screen has
  /// no such field — but it still has to survive a trip to login and back.
  String get displayName => _displayName;

  void rememberEmail(String value) => _email = value.trim();

  void rememberDisplayName(String value) => _displayName = value.trim();

  void clear() {
    _email = '';
    _displayName = '';
  }
}
