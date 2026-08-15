import 'package:flutter/material.dart';

import '../../../../core/design_system/widgets/qeran_bottom_nav.dart';
import '../../../../core/widgets/scroll_hiding_nav_scaffold.dart';

/// Lifts the chat composer clear of the shell's floating nav island while that
/// island is on screen, and lets it settle onto the bottom edge once it slides
/// away.
///
/// The Messages tab is the only tab whose content is pinned to the bottom
/// rather than scrolled, so it is the only one the floating nav can cover. Every
/// other tab already reserves the island through
/// [QeranBottomNav.contentClearance] on its scrollable.
///
/// The reversed message list makes this mandatory rather than cosmetic: in a
/// `reverse: true` ListView, returning to the newest message is an UPWARD
/// scroll, which is exactly the gesture that brings the nav back. A reader
/// arriving at the composer to type therefore does so with the island rising
/// over it.
///
/// Outside a [ScrollHidingNavScaffold] — the matchmaker opens conversations as
/// a pushed route — there is no nav to avoid and the padding stays zero.
class NavAwareComposer extends StatelessWidget {
  const NavAwareComposer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final navVisible = BottomNavVisibility.maybeOf(context) ?? false;
    // contentClearance bundles the island's footprint WITH the device inset.
    // The composer's own SafeArea already covers that inset, so it is taken
    // back out here rather than paid for twice.
    final islandFootprint =
        QeranBottomNav.contentClearance(context) -
        MediaQuery.viewPaddingOf(context).bottom;
    return AnimatedPadding(
      // Travels with the island so the two never cross mid-flight.
      duration: ScrollHidingNavScaffold.duration,
      curve: ScrollHidingNavScaffold.curve,
      padding: EdgeInsets.only(bottom: navVisible ? islandFootprint : 0),
      child: child,
    );
  }
}
