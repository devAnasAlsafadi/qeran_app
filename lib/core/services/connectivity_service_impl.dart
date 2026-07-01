import 'package:connectivity_plus/connectivity_plus.dart';

import '../app_logger.dart';
import 'connectivity_service.dart';

/// `connectivity_plus`-backed [ConnectivityService].
///
/// Collapses the plugin's `List<ConnectivityResult>` to a single boolean:
/// online when the list holds any transport other than
/// [ConnectivityResult.none]. The plugin reports interface state, not true
/// reachability — genuine "connected-but-no-internet" cases are caught
/// reactively at the HTTP layer (SocketException → OfflineException) in a
/// later sub-step.
class ConnectivityServiceImpl implements ConnectivityService {
  ConnectivityServiceImpl({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static const String _tag = 'CONNECTIVITY';

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Future<bool> get isOnline async {
    try {
      return _isOnline(await _connectivity.checkConnectivity());
    } catch (e) {
      // Fail open: if the platform can't be queried, assume online so a
      // plugin hiccup never blocks requests. The HTTP layer still fast-fails
      // on the real SocketException when the network is actually down.
      AppLogger.warning('checkConnectivity failed: $e', tag: _tag);
      return true;
    }
  }

  @override
  Stream<bool> get onStatusChange => _statusStream;

  // Deduped (`.distinct()`) so it emits only on a real flip, and broadcast so
  // the HTTP pre-flight and the banner cubit can both listen.
  late final Stream<bool> _statusStream = _connectivity.onConnectivityChanged
      .map(_isOnline)
      .distinct()
      .map(_logTransition)
      .asBroadcastStream();

  bool _logTransition(bool online) {
    AppLogger.info(online ? 'offline → online' : 'online → offline', tag: _tag);
    return online;
  }
}
