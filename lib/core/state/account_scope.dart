import 'package:qeran/core/app_logger.dart';

/// What the app keeps for the signed-in account outside any screen: the
/// app-scoped cubits, the in-memory caches, the per-run flags. Each holder
/// joins with [hold] where it is registered (its feature's DI), and the
/// session calls [forgetAccount] whenever the account changes — sign-out, a
/// deleted account, a different account signing in — so the next account on
/// this phone never starts from the previous one's state.
///
/// Forgetting is synchronous on purpose: by the time the session announces
/// the change, nothing of the previous account is left to show. A holder
/// with a request in flight drops its answer when it lands.
class AccountScope {
  final List<void Function()> _forgetters = [];

  /// Joins [holder]: [forget] runs on every account change. Returns [holder],
  /// so a lazy singleton's factory can wrap its construction — a holder never
  /// built holds nothing to forget.
  T hold<T>(T holder, void Function(T holder) forget) {
    _forgetters.add(() => forget(holder));
    return holder;
  }

  /// Every holder forgets the account. One that throws is logged and the
  /// rest still forget.
  void forgetAccount() {
    for (final forget in _forgetters) {
      try {
        forget();
      } catch (e, s) {
        AppLogger.error(
          'A holder failed to forget the account',
          error: e,
          stack: s,
          tag: 'SESSION',
        );
      }
    }
  }
}
