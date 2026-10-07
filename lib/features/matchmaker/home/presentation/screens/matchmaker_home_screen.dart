import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qeran/features/badges/domain/entities/nav_badge_tabs.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../../core/widgets/scroll_hiding_nav_scaffold.dart';
import '../../../notifications/presentation/routing/open_notified.dart';
import '../../../shared/data/matchmaker_notification_router.dart';
import '../../../users/domain/entities/matchmaker_users_list.dart';
import '../home_shell_scope.dart';
import '../matchmaker_push_routing.dart';
import '../matchmaker_push_taps.dart';
import '../widgets/matchmaker_bottom_nav.dart';
import '../widgets/matchmaker_shell_hosts.dart';
import '../widgets/matchmaker_shell_tabs.dart';

/// Matchmaker (role=Moderator) shell. Shares the user `HomeScreen`'s shell
/// geometry through [ScrollHidingNavScaffold] — floating island, scroll-away
/// nav, same `QeranBottomNav`. Only the items + bodies differ.
///
/// [MatchmakerShellTabs] keeps each tab alive across switches;
/// [MatchmakerShellHosts] holds what lives above them.
class MatchmakerHomeScreen extends StatefulWidget {
  const MatchmakerHomeScreen({super.key, this.pushTaps});

  /// Where her tapped pushes come from; Firebase's when null.
  final MatchmakerPushTaps? pushTaps;

  @override
  State<MatchmakerHomeScreen> createState() => _MatchmakerHomeScreenState();
}

class _MatchmakerHomeScreenState extends State<MatchmakerHomeScreen> {
  // Tab indices follow [MatchmakerShellTabs].
  int _currentTab = 0;
  MatchmakerUsersList _usersSubTab = MatchmakerUsersList.pending;

  /// True while the visible tab was reached from a notification — see
  /// [_openFromNotification]. Drives the destination's back control.
  bool _fromNotification = false;

  late final MatchmakerPushRouting _push = MatchmakerPushRouting(
    taps: widget.pushTaps,
    onOpen: (link) {
      if (mounted) _openFromNotification(link);
    },
  );

  @override
  void initState() {
    super.initState();
    // A new shell means a new session — start from the server's counts rather
    // than whatever the last account left behind.
    sl<BadgesCubit>().clear();
    unawaited(sl<BadgesCubit>().refresh());
    _push.start();
  }

  @override
  void dispose() {
    _push.dispose();
    super.dispose();
  }

  /// The single entry point for BOTH notification paths — a row tapped in the
  /// inbox (handed back when it pops) and a system push tapped outside the app.
  /// Raises [_fromNotification], which is what puts a back control on the
  /// destination tab.
  ///
  /// Raised OUTSIDE the tab switch on purpose: `_selectTab` returns early when
  /// the target tab is already showing, and that is exactly when the control
  /// matters most — nothing else on screen changes.
  void _openFromNotification(MatchmakerDeepLink link) {
    if (link is IgnoreDeepLink) return;
    if (mounted) setState(() => _fromNotification = true);
    switch (link) {
      case OpenCases():
        _selectTab(
          2,
        ); // Cases tab — the shell owns selection (no route change).
      case OpenUserChat():
        openNotifiedChat(context, link);
      case IgnoreDeepLink():
        break;
    }
  }

  /// Opening a tab acknowledges its badge. Ahead of the early return below on
  /// purpose: a live event can raise a dot on the tab already showing, and a
  /// visible dot that ignores a tap reads as broken. No-ops when the tab has
  /// no badge, so a repeat visit costs nothing.
  void _markTabSeen(int index) {
    final key = NavBadgeTabs.matchmaker[index];
    if (key != null) unawaited(sl<BadgesCubit>().markSeen(key));
  }

  void _selectTab(int index, {MatchmakerUsersList? usersSubTab}) {
    _markTabSeen(index);
    if (index == _currentTab && usersSubTab == null) return;
    setState(() {
      _currentTab = index;
      if (usersSubTab != null) _usersSubTab = usersSubTab;
    });
  }

  /// Reopens the inbox and applies whatever the user taps there next — a fresh
  /// notification wins over the one that brought them here.
  ///
  /// Both the back arrow and the Android back button land here, so there is one
  /// behaviour rather than two. Clearing the flag is part of it: the trail is
  /// spent once it has been followed, and popping the inbox without tapping
  /// anything leaves the tab as an ordinary tab.
  Future<void> _returnToNotifications() async {
    if (_fromNotification) setState(() => _fromNotification = false);
    final result = await Navigator.of(
      context,
    ).pushNamed(RouteNames.matchmakerNotifications);
    if (!mounted || result is! MatchmakerDeepLink) return;
    _openFromNotification(result);
  }

  /// A manual bottom-nav tap ends the notification trail — otherwise the back
  /// control would sit there forever, pointing at an inbox the user has since
  /// left by hand.
  void _onNavTap(int index) {
    if (_fromNotification) setState(() => _fromNotification = false);
    _selectTab(index);
  }

  void _changeUsersSubTab(MatchmakerUsersList sub) {
    if (sub == _usersSubTab) return;
    setState(() => _usersSubTab = sub);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Only while the trail is live. Otherwise the system back keeps its
      // default meaning — pop the shell, or leave the app from the root.
      canPop: !_fromNotification,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _returnToNotifications();
      },
      child: MatchmakerShellHosts(
        child: MatchmakerHomeShellScope(
          openTab: _selectTab,
          openFromNotification: _openFromNotification,
          fromNotification: _fromNotification,
          returnToNotifications: _returnToNotifications,
          child: _tabs(),
        ),
      ),
    );
  }

  Widget _tabs() => ScrollHidingNavScaffold(
    currentIndex: _currentTab,
    body: MatchmakerShellTabs(
      currentIndex: _currentTab,
      usersSubTab: _usersSubTab,
      onUsersSubTabChanged: _changeUsersSubTab,
    ),
    navBuilder: (context) =>
        MatchmakerBottomNav(currentIndex: _currentTab, onTap: _onNavTap),
  );
}
