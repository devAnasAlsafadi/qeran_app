import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_nav.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/utils/keyboard_dismissal.dart';
import 'package:qeran/core/widgets/locale_rebuild_scope.dart';
import 'package:qeran/core/widgets/scroll_hiding_nav_scaffold.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/badges/domain/entities/badge_counts.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/features/chat/domain/ports/chat_realtime_port.dart';
import 'package:qeran/features/chat/presentation/screens/chat_entry_screen.dart';
import 'package:qeran/features/chat/presentation/widgets/chat_realtime_host.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_view.dart';
import 'package:qeran/features/home/presentation/home_shell_scope.dart';
import 'package:qeran/features/likes/presentation/screens/likes_screen.dart';
import 'package:qeran/features/notifications/presentation/routing/notification_deep_link.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/profile/presentation/screens/profile_screen.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Home shell. Hosts the Discovery deck (with its own top bar — title +
/// filter + notification bell) and the bottom navigation.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const int _discoveryTabIndex = 0;
  static const int _likesTabIndex = 1;
  static const int _messagesTabIndex = 2;
  static const int _profileTabIndex = 3;
  int _currentTab = _discoveryTabIndex;
  int? _previousTab;
  int _tabDirection = 1;
  bool _tabTransitionPending = false;
  int _messagesRefreshEpoch = 0;

  /// True while the visible tab was reached from a notification — see
  /// [_openFromNotification]. Drives the destination's back control.
  bool _fromNotification = false;

  late final AnimationController _tabTransition = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  late final CurvedAnimation _tabCurve = CurvedAnimation(
    parent: _tabTransition,
    curve: Curves.easeOutCubic,
  );

  // Tabs mount lazily: an index enters this set the first time it is shown and
  // stays (IndexedStack keeps it alive after), so each tab fetches on first
  // visit and never re-fetches on later switches. Seeded with the tab shown at
  // shell entry so only that one loads on cold start.
  final Set<int> _visited = {_discoveryTabIndex};

  // FCM deep-linking. Confined to the shell — mirrors the matchmaker shell
  // (no main.dart bootstrap changes). Role-guarded so a matchmaker-targeted
  // push never acts on the user tree. The shell's SignalR carries chat traffic
  // only, so the foreground stream is what refreshes the badges here.
  StreamSubscription<RemoteMessage>? _notifTapSub;
  StreamSubscription<RemoteMessage>? _notifForegroundSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A new shell means a new signed-in session. Refresh the app-scoped gate
    // instead of reusing another account's resolved status. Fetch failures
    // remain fail-open; the backend stays the real action gate.
    unawaited(sl<ProfileGateCubit>().refresh());
    // A new shell means a new session — start from the server's counts rather
    // than whatever the last account left behind.
    sl<BadgesCubit>().clear();
    unawaited(sl<BadgesCubit>().refresh());
    // Background-tap (app alive) + terminated/cold-start (launched by tap).
    _notifTapSub = FirebaseMessaging.onMessageOpenedApp.listen(_route);
    FirebaseMessaging.instance.getInitialMessage().then((m) {
      if (m != null) _route(m);
    });
    // Foreground push → refresh the unread indicators (no auto-navigation).
    _notifForegroundSub = FirebaseMessaging.onMessage.listen((_) {
      unawaited(sl<BadgesCubit>().refresh());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_notifTapSub?.cancel());
    unawaited(_notifForegroundSub?.cancel());
    _tabCurve.dispose();
    _tabTransition.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(sl<BadgesCubit>().refresh());
      unawaited(sl<CurrentSubscriptionCubit>().refresh(force: true));
    }
  }

  /// Route a tapped notification into a bottom-nav tab. Defensive role guard:
  /// only the regular user shell acts (a Moderator push routes elsewhere).
  /// Non-actionable payloads ([NoDeepLink]) do nothing.
  void _route(RemoteMessage message) {
    if (!mounted) return;
    final role = sl<UserSessionCubit>().currentUser?.role;
    if ((role ?? '').toLowerCase() == 'moderator') return;
    _openFromNotification(NotificationDeepLinkRouter.resolveData(message.data));
  }

  /// The single entry point for BOTH notification paths — a row tapped in the
  /// inbox (handed back by `openNotifications`) and a system push tapped
  /// outside the app. Switches the tab and raises [_fromNotification], which is
  /// what puts a back control on the destination.
  ///
  /// The flag is raised OUTSIDE the tab switch on purpose: `_selectTab` returns
  /// early when the target is already showing, and that is exactly the case
  /// where the control matters most — nothing else on screen changes, so it is
  /// the only sign the tap did anything.
  void _openFromNotification(NotificationDeepLink link) {
    if (link is NoDeepLink) return;
    if (mounted) setState(() => _fromNotification = true);
    switch (link) {
      case OpenLikesTab():
        _openLikesTab();
      case OpenMessagesTab():
        _openMessagesTab();
      case OpenProfileTab():
        _openProfileTab();
      case NoDeepLink():
        break;
    }
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
    ).pushNamed(RouteNames.notifications);
    if (!mounted || result is! NotificationDeepLink) return;
    _openFromNotification(result);
  }

  /// A manual bottom-nav tap ends the notification trail — otherwise the back
  /// control would sit there forever, pointing at an inbox the user has since
  /// navigated away from by hand.
  void _onNavTap(int index) {
    if (_fromNotification) setState(() => _fromNotification = false);
    _selectTab(index);
  }

  Future<void> _selectTab(int index) async {
    if (index == _currentTab || _tabTransitionPending) return;
    // Visited tabs stay mounted offstage. Clear a composer/form focus before
    // hiding its tab so Android cannot restore that invisible field (and its
    // keyboard) over the newly selected tab later.
    unawaited(dismissKeyboard());
    _tabTransitionPending = true;
    final firstVisit = !_visited.contains(index);
    if (firstVisit) {
      // Build the destination offstage first. Its initial layout/fetch can no
      // longer land on the first frame of the visible tab transition.
      setState(() => _visited.add(index));
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }

    final previous = _currentTab;
    setState(() {
      _previousTab = previous;
      _tabDirection = index > previous ? 1 : -1;
      _currentTab = index;
    });
    try {
      await _tabTransition.forward(from: 0);
    } finally {
      if (mounted) {
        setState(() => _previousTab = null);
      }
      _tabTransitionPending = false;
    }
  }

  Widget _tabBody(int index) => switch (index) {
    _discoveryTabIndex => const DiscoveryView(),
    _likesTabIndex => const LikesScreen(),
    // The Messages tab already takes an onBack for its pushed copy; reached
    // from a notification it needs the same control. (Only the system-push path
    // lands here — a chat row tapped in the inbox pushes over it instead.)
    _messagesTabIndex => ChatEntryScreen(
      key: ValueKey<String>('chat-entry-$_messagesRefreshEpoch'),
      onBack: _fromNotification ? _returnToNotifications : null,
    ),
    _profileTabIndex => const ProfileScreen(),
    _ => const SizedBox.shrink(),
  };

  Widget _tabEntry(
    int index, {
    required bool enabled,
    bool offstage = false,
    Offset offset = Offset.zero,
  }) {
    return KeyedSubtree(
      key: ValueKey<String>('home-tab-$index'),
      child: Offstage(
        offstage: offstage,
        child: Transform.translate(
          offset: offset,
          child: TickerMode(
            enabled: enabled,
            child: IgnorePointer(
              ignoring: !enabled || _tabTransition.isAnimating,
              // Tabs stay mounted, so without this a language switch would
              // leave every already-fetched tab in the old language until the
              // user pulled to refresh it by hand.
              child: RepaintBoundary(
                child: LocaleRebuildScope(child: _tabBody(index)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Keeps visited tabs alive while giving the active pair a transform-only
  /// page transition. No full-screen Opacity/saveLayer is introduced.
  Widget _buildTabStage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isRtl = Directionality.of(context) == TextDirection.rtl;
        final direction = _tabDirection * (isRtl ? -1 : 1);
        return ClipRect(
          child: AnimatedBuilder(
            animation: _tabCurve,
            builder: (context, _) {
              final previous = _previousTab;
              final t = previous == null ? 1.0 : _tabCurve.value;
              return Stack(
                fit: StackFit.expand,
                children: [
                  for (final index in _visited)
                    if (index != _currentTab && index != previous)
                      _tabEntry(index, enabled: false, offstage: true),
                  if (previous != null)
                    _tabEntry(
                      previous,
                      enabled: true,
                      offset: Offset(-direction * width * 0.18 * t, 0),
                    ),
                  _tabEntry(
                    _currentTab,
                    enabled: true,
                    offset: Offset(direction * width * (1.0 - t), 0),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _openLikesTab() => _selectTab(_likesTabIndex);
  void _openMessagesTab({bool refresh = false}) {
    if (refresh && mounted) {
      setState(() => _messagesRefreshEpoch++);
    }
    _selectTab(_messagesTabIndex);
  }

  void _openProfileTab() => _selectTab(_profileTabIndex);

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
      // Owns the `/hubs/chat` session for the whole user shell — the hub feeds
      // every tab, so it must not depend on Messages having been opened.
      child: ChatRealtimeHost(
        port: sl<ChatRealtimePort>(),
        accessTokenProvider: sl<ChatAccessTokenProvider>(),
        child: HomeShellScope(
          openLikesTab: _openLikesTab,
          openMessagesTab: _openMessagesTab,
          openProfileTab: _openProfileTab,
          openFromNotification: _openFromNotification,
          fromNotification: _fromNotification,
          returnToNotifications: _returnToNotifications,
          child: BlocBuilder<BadgesCubit, BadgeCounts>(
            bloc: sl<BadgesCubit>(),
            builder: (context, badges) {
              // Dots, not numbers: a tab stands for one thing, so "there is
              // something here" is the whole message. The real count is passed
              // regardless — it decides whether the dot shows at all, and it
              // leaves the door open to numbers without a design-system change.
              //
              // Discovery carries none. `exploreUnread` is documented as
              // permanently zero, and a tab that can never light must not wear
              // a badge implying it might.
              final items = <QeranNavItem>[
                QeranNavItem(
                  outlineIcon: Icons.diamond_outlined,
                  filledIcon: Icons.diamond_rounded,
                  label: LocaleKeys.home_nav_marriage.t(context),
                ),
                QeranNavItem(
                  outlineIcon: Icons.favorite_border_rounded,
                  filledIcon: Icons.favorite_rounded,
                  label: LocaleKeys.home_nav_likes.t(context),
                  badgeCount: badges.likes,
                  badgeIsDot: true,
                ),
                QeranNavItem(
                  outlineIcon: Icons.chat_bubble_outline_rounded,
                  filledIcon: Icons.chat_bubble_rounded,
                  label: LocaleKeys.home_nav_messages.t(context),
                  badgeCount: badges.chat,
                  badgeIsDot: true,
                ),
                QeranNavItem(
                  outlineIcon: Icons.person_outline_rounded,
                  filledIcon: Icons.person_rounded,
                  label: LocaleKeys.home_nav_profile.t(context),
                  badgeCount: badges.account,
                  badgeIsDot: true,
                ),
              ];
              return ScrollHidingNavScaffold(
                currentIndex: _currentTab,
                body: _buildTabStage(),
                navBuilder: (context) => QeranBottomNav(
                  items: items,
                  currentIndex: _currentTab,
                  onTap: _onNavTap,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
