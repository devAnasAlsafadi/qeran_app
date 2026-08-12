import 'package:qeran/core/di/injection_container.dart';

/// The app-scoped memo, or a throwaway one when the container has not been
/// booted. Widget tests that register only the blocs they need therefore get
/// an isolated instance rather than a lookup crash — and isolation between
/// tests is the behaviour they want regardless.
AuthEmailMemo resolveAuthEmailMemo() =>
    sl.isRegistered<AuthEmailMemo>() ? sl<AuthEmailMemo>() : AuthEmailMemo();

/// Carries the email the member has typed across a login ↔ register hop.
///
/// The two screens own their own [TextEditingController]s and are built fresh
/// on every navigation, so the field is empty by construction when they come
/// back. This holds the one value worth restoring.
///
/// EMAIL ONLY, deliberately. The password is not kept: a long-lived plaintext
/// password in memory buys a small convenience for a real exposure, and the
/// member re-typing it is the correct trade for a matrimony account.
///
/// In-memory and not persisted — it exists for the duration of one auth
/// attempt, and is cleared the moment sign-in or registration succeeds.
class AuthEmailMemo {
  String _email = '';

  String get email => _email;

  void remember(String value) => _email = value.trim();

  void clear() => _email = '';
}
