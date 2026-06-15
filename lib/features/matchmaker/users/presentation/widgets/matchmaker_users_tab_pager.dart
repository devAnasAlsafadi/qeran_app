import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_motion.dart';
import '../../domain/entities/matchmaker_users_list.dart';
import 'keep_alive_page.dart';
import 'matchmaker_subscribed_with_plan_filter.dart';
import 'matchmaker_users_list_view.dart';

/// Animated, directional body for the three Users sub-tabs.
///
/// A controlled, NON-swipeable [PageView]: the segmented control (and the
/// dashboard shortcuts) remain the only drivers — there's no new swipe gesture
/// — but switching now slides directionally instead of hard-cutting. Moving to
/// a later tab slides forward, earlier slides back; [PageView] honours the
/// ambient [Directionality], so the sense mirrors correctly under RTL with no
/// hardcoded left/right.
///
/// Each page is wrapped in [KeepAlivePage] so per-tab pagination + scroll
/// survive switches, preserving the old [IndexedStack] behaviour.
///
/// Timing matches [QeranMotion.standard] / [QeranCurves.standard] — the same
/// duration + curve the segmented control's gold indicator uses, so the body
/// and indicator travel in lockstep.
class MatchmakerUsersTabPager extends StatefulWidget {
  const MatchmakerUsersTabPager({
    super.key,
    required this.activeIndex,
    required this.onPageChanged,
  });

  /// Active sub-tab index (0..2), driven by the shell.
  final int activeIndex;

  /// Reports a settled page change back to the shell (keeps the segmented
  /// control + shell state in sync).
  final ValueChanged<MatchmakerUsersList> onPageChanged;

  @override
  State<MatchmakerUsersTabPager> createState() =>
      _MatchmakerUsersTabPagerState();
}

class _MatchmakerUsersTabPagerState extends State<MatchmakerUsersTabPager> {
  late final PageController _controller =
      PageController(initialPage: widget.activeIndex);

  @override
  void didUpdateWidget(MatchmakerUsersTabPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    // External driver (segmented control / dashboard shortcut) changed the
    // tab — animate to it. Guard against re-animating to the page we're
    // already on (e.g. when our own onPageChanged round-trips through the
    // shell), which would otherwise interrupt or loop.
    if (widget.activeIndex != oldWidget.activeIndex &&
        _currentPage != widget.activeIndex) {
      _controller.animateToPage(
        widget.activeIndex,
        duration: QeranMotion.standard,
        curve: QeranCurves.standard,
      );
    }
  }

  /// The controller's current (rounded) page, or the initial index before the
  /// controller is attached to a viewport.
  int get _currentPage =>
      _controller.hasClients && _controller.page != null
          ? _controller.page!.round()
          : widget.activeIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _controller,
      // Controlled only — no new swipe gesture (matches the prior behaviour).
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (i) =>
          widget.onPageChanged(MatchmakerUsersList.values[i]),
      children: const [
        KeepAlivePage(
          child: MatchmakerUsersListView(list: MatchmakerUsersList.pending),
        ),
        KeepAlivePage(
          child: MatchmakerUsersListView(
            list: MatchmakerUsersList.approvedUnsubscribed,
          ),
        ),
        // Subscribed page carries the dynamic plan-filter rail above its list.
        KeepAlivePage(child: MatchmakerSubscribedWithPlanFilter()),
      ],
    );
  }
}
