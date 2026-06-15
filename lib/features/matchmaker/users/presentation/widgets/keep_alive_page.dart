import 'package:flutter/material.dart';

/// Keeps its [child] alive inside a lazy viewport (e.g. [PageView]) so the
/// child's state — here each Users list's pagination + scroll — survives tab
/// switches, matching the old [IndexedStack] behaviour while the page slides.
class KeepAlivePage extends StatefulWidget {
  const KeepAlivePage({super.key, required this.child});

  final Widget child;

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by the mixin
    return widget.child;
  }
}
