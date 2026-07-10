import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';

import '../services/connectivity_service.dart';

/// Whether the device currently has a network connection, for the offline
/// banner.
enum ConnectivityStatus { online, offline }

/// App-wide connectivity signal driving the offline banner. Root-provided with
/// singleton lifetime. Seeds `online` optimistically, corrects to the real
/// snapshot on construction, then follows [ConnectivityService] transitions.
class ConnectivityCubit extends Cubit<ConnectivityStatus> with SafeEmit<ConnectivityStatus> {
  ConnectivityCubit({required ConnectivityService service})
      : _service = service,
        super(ConnectivityStatus.online) {
    _sub = _service.onStatusChange.listen(_apply);
    unawaited(_hydrate());
  }

  final ConnectivityService _service;
  StreamSubscription<bool>? _sub;

  Future<void> _hydrate() async => _apply(await _service.isOnline);

  void _apply(bool online) {
    if (isClosed) return;
    emit(online ? ConnectivityStatus.online : ConnectivityStatus.offline);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
