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

  /// Breathing room between the composer's bottom edge and the island's
  /// topmost painted pixel. Small on purpose — the two should read as a stack,
  /// not as two bars with a corridor between them.
  static const double _gap = 6;

  @override
  Widget build(BuildContext context) {
    final nav = BottomNavGeometry.maybeOf(context);
    final navVisible = nav?.visible ?? false;
    // The inset comes from the shell, NOT from MediaQuery: Scaffold strips the
    // bottom padding from its body when a bottomNavigationBar is present, and
    // removePadding takes it out of viewPadding too, so both read 0 down here.
    // Reading them was the regression — the composer lost the whole inset and
    // sank into the island by exactly that much.
    final inset = nav?.insetBottom ?? MediaQuery.viewPaddingOf(context).bottom;
    // Measured to the island's PAINT (the gold disc crests above the bar), not
    // to its layout box and not via contentClearance, which omits bMargin so
    // that scrolled content passes underneath — the opposite of what a pinned
    // composer needs.
    final island = QeranBottomNav.islandPaintedHeight(context) + _gap;
    return AnimatedPadding(
      // Travels with the island so the two never cross mid-flight.
      duration: ScrollHidingNavScaffold.duration,
      curve: ScrollHidingNavScaffold.curve,
      padding: EdgeInsets.only(bottom: inset + (navVisible ? island : 0)),
      // This widget owns the device inset now, so the composer's own SafeArea
      // must stop claiming it. That double payment WAS the dead band under the
      // text field: once the composer is lifted off the screen edge, its
      // SafeArea keeps reserving the home-indicator strip inside the bar, where
      // nothing needs protecting. Removed unconditionally rather than only
      // while the island is up — flipping it per state would collapse the bar
      // by the inset in one frame while the padding was still animating.
      child: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: child,
      ),
    );
  }
}
