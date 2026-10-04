import 'package:flutter/widgets.dart';

/// A Community screen kept longer than [maxAge] reads itself again when the
/// app comes back to the foreground or the screen is shown again (S19): a
/// video's signed links last 6 h, so an older copy would play nothing.
class CommunityStaleRefresh extends StatefulWidget {
  const CommunityStaleRefresh({
    super.key,
    required this.onStale,
    required this.child,
    this.maxAge = const Duration(hours: 6),
    this.now = DateTime.now,
  });

  final VoidCallback onStale;
  final Widget child;
  final Duration maxAge;
  final DateTime Function() now;

  @override
  State<CommunityStaleRefresh> createState() => _CommunityStaleRefreshState();
}

class _CommunityStaleRefreshState extends State<CommunityStaleRefresh>
    with WidgetsBindingObserver {
  /// When it was last read — its mount, then each refresh.
  late DateTime _since;
  bool _shown = true;

  @override
  void initState() {
    super.initState();
    _since = widget.now();
    WidgetsBinding.instance.addObserver(this);
  }

  /// Shown again: its tab chosen, or the route over it gone.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shown =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    if (shown && !_shown) _check();
    _shown = shown;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _shown) _check();
  }

  void _check() {
    final now = widget.now();
    if (now.difference(_since) <= widget.maxAge) return;
    _since = now;
    widget.onStale();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
