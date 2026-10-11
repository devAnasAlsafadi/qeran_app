import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/app_route_tracker.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/core/session/session_expiry.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'blocs/user_session/user_session_cubit.dart';

/// C4 (Q25, TQ11): a 401 to our Bearer signs the account out once, however
/// many requests fail together, and lands on login with «انتهت الجلسة», in
/// both roles.
///
/// A report counts only while its token is still the stored one: a request
/// that left before a sign-out, or before a new sign-in, carries a token that
/// is already gone. Reports arriving while one is handled are the same
/// session's, so they are dropped.
class SessionExpiryHandler {
  SessionExpiryHandler({
    required SessionExpiry expiry,
    required UserSessionCubit session,
    required StorageService secureStorage,
    required GlobalKey<NavigatorState> navigator,
    required AppRouteTracker routes,
  }) : _expiry = expiry,
       _session = session,
       _secureStorage = secureStorage,
       _navigator = navigator,
       _routes = routes;

  final SessionExpiry _expiry;
  final UserSessionCubit _session;
  final StorageService _secureStorage;
  final GlobalKey<NavigatorState> _navigator;
  final AppRouteTracker _routes;

  StreamSubscription<String>? _reports;
  bool _handling = false;

  /// Listens from now on; once is enough.
  void start() => _reports ??= _expiry.reports.listen(_onReport);

  Future<void> _onReport(String token) async {
    if (_handling) return;
    _handling = true;
    try {
      // The splash reads the token once and then routes; signing out before
      // it has would let it route on into the app without one.
      await _routes.whenNotOn(RouteNames.splashScreen);
      if (await _secureStorage.get<String>(StorageKeys.token) != token) return;
      AppLogger.warning('Session expired (401) — signing out', tag: 'SESSION');
      await _session.expireSession();
      _toLogin();
    } catch (e, s) {
      AppLogger.error(
        'Session expiry failed',
        error: e,
        stack: s,
        tag: 'SESSION',
      );
    } finally {
      _handling = false;
    }
  }

  /// Login over everything, then the notice — resolved first, from the
  /// navigator's own context, which outlives the routes it removes.
  void _toLogin() {
    final navigator = _navigator.currentState;
    if (navigator == null) return;
    final message = LocaleKeys.errors_unauthorized.t(navigator.context);
    navigator.pushNamedAndRemoveUntil(RouteNames.loginScreen, (_) => false);
    unawaited(
      AppSnackBar.showOnRoot(message: message, type: SnackBarType.notice),
    );
  }
}
