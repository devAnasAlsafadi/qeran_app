import 'package:flutter/widgets.dart';
import 'package:qeran/core/design_system/widgets/qeran_connectivity_banner.dart';

/// Shows the offline banner while [offline] — the app decides what that means
/// (no connection, and a signed-in session).
///
/// By default the banner overlays the top of whichever route is showing. A page
/// wrapped in [AttachedConnectivityBanner] shows it in its own layout instead,
/// at a [ConnectivityBannerSlot] under its bar or header, where it covers
/// nothing; while such a page is the top route, the overlay stands down.
class ConnectivityBannerHost extends StatefulWidget {
  const ConnectivityBannerHost({
    super.key,
    required this.offline,
    required this.child,
  });

  final bool offline;
  final Widget child;

  @override
  State<ConnectivityBannerHost> createState() => _ConnectivityBannerHostState();
}

class _ConnectivityBannerHostState extends State<ConnectivityBannerHost> {
  /// Slots whose route is on top: normally one, briefly two while one
  /// attaching page replaces another.
  final Set<State> _onTop = {};
  bool _rebuildPending = false;

  /// Slots report from their build, so the overlay catches up after the frame.
  void _report(State slot, {required bool onTop}) {
    final changed = onTop ? _onTop.add(slot) : _onTop.remove(slot);
    if (!changed || _rebuildPending) return;
    _rebuildPending = true;
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        _rebuildPending = false;
        if (mounted) setState(() {});
      })
      ..ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return _HostScope(
      offline: widget.offline,
      report: _report,
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: QeranConnectivityBanner(
              visible: widget.offline && _onTop.isEmpty,
            ),
          ),
        ],
      ),
    );
  }
}

class _HostScope extends InheritedWidget {
  const _HostScope({
    required this.offline,
    required this.report,
    required super.child,
  });

  final bool offline;
  final void Function(State slot, {required bool onTop}) report;

  static _HostScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_HostScope>();

  @override
  bool updateShouldNotify(_HostScope old) => offline != old.offline;
}

/// Marks a page that shows the offline banner under its own bar or header, at
/// a [ConnectivityBannerSlot], rather than under the app-wide overlay.
///
/// Shared widgets can hold a slot and stay inert on pages that don't opt in:
/// the chat header is also the matchmaker app's, which keeps the overlay.
class AttachedConnectivityBanner extends InheritedWidget {
  const AttachedConnectivityBanner({super.key, required super.child});

  static bool _on(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AttachedConnectivityBanner>() !=
      null;

  @override
  bool updateShouldNotify(AttachedConnectivityBanner old) => false;
}

/// Where the offline banner attaches, under a bar or header: it slides out from
/// under it and pushes the content down. Takes no space on a page that hasn't
/// opted in with [AttachedConnectivityBanner], or with no host above.
class ConnectivityBannerSlot extends StatefulWidget {
  const ConnectivityBannerSlot({super.key});

  @override
  State<ConnectivityBannerSlot> createState() => _ConnectivityBannerSlotState();
}

class _ConnectivityBannerSlotState extends State<ConnectivityBannerSlot> {
  _HostScope? _host;

  @override
  Widget build(BuildContext context) {
    final host = _HostScope.maybeOf(context);
    if (host == null || !AttachedConnectivityBanner._on(context)) {
      return const SizedBox.shrink();
    }
    _host = host;
    // Only the top route's slot stands the overlay down: under a pushed page
    // that doesn't attach the banner, the overlay comes back.
    host.report(this, onTop: ModalRoute.of(context)?.isCurrent ?? true);
    return QeranConnectivityBanner(visible: host.offline, attached: true);
  }

  @override
  void dispose() {
    _host?.report(this, onTop: false);
    super.dispose();
  }
}
