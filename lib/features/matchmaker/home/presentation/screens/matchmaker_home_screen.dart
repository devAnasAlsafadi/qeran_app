import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/badges/domain/entities/nav_badge_tabs.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/features/badges/presentation/widgets/badges_realtime_host.dart';
import 'package:qeran/features/chat/domain/ports/chat_realtime_port.dart';
import 'package:qeran/features/chat/presentation/widgets/chat_realtime_host.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../../core/widgets/locale_rebuild_scope.dart';
import '../../../../../core/widgets/scroll_hiding_nav_scaffold.dart';
import '../../../compatibility_cases/presentation/screens/matchmaker_cases_tab.dart';
import '../../../conversations/domain/entities/matchmaker_conversation.dart';
import '../../../conversations/presentation/screens/matchmaker_conversations_tab.dart';
import '../../../dashboard/presentation/blocs/matchmaker_dashboard_cubit.dart';
import '../../../dashboard/presentation/screens/matchmaker_dashboard_tab.dart';
import '../../../explore/presentation/screens/matchmaker_explore_tab.dart';
import '../../../shared/data/matchmaker_notification_router.dart';
import '../../../shared/domain/entities/matchmaker_realtime_status.dart';
import '../../../shared/domain/ports/matchmaker_realtime_port.dart';
import '../../../users/domain/entities/matchmaker_users_list.dart';
import '../../../users/presentation/screens/matchmaker_users_tab.dart';
import '../home_shell_scope.dart';
import '../widgets/matchmaker_bottom_nav.dart';

/// Matchmaker (role=Moderator) shell. Shares the user `HomeScreen`'s shell
/// geometry through [ScrollHidingNavScaffold] — floating island, scroll-away
/// nav, same `QeranBottomNav`. Only the items + bodies differ.
///
/// `IndexedStack` keeps each tab's state alive across switches. The
/// dashboard cubit is provided here (above the stack) so both the
/// Dashboard tab and the Users tab's pending badge read the same stats.
class MatchmakerHomeScreen extends StatefulWidget {
  const MatchmakerHomeScreen({super.key});

  @override
  State<MatchmakerHomeScreen> createState() => _MatchmakerHomeScreenState();
}

class _MatchmakerHomeScreenState extends State<MatchmakerHomeScreen>
    with WidgetsBindingObserver {
  // Tab indices follow the IndexedStack order below.
  // 0 = Dashboard · 1 = Users · 2 = Cases · 3 = Conversations · 4 = Explore.
  int _currentTab = 0;
  MatchmakerUsersList _usersSubTab = MatchmakerUsersList.pending;

  /// True while the visible tab was reached from a notification — see
  /// [_openFromNotification]. Drives the destination's back control.
  bool _fromNotification = false;

  // Tabs mount lazily: an index enters this set the first time it is shown and
  // stays (IndexedStack keeps it alive after), so each tab fetches on first
  // visit and never re-fetches on later switches. Seeded with the Dashboard
  // (index 0) shown at shell entry. The realtime port, dashboard cubit and
  // bell badge are owned above the stack in initState/build — untouched here.
  final Set<int> _visited = {0};

  // App-wide matchmaker realtime connection (M4c-1). Owned here so it
  // stays alive across all tabs, independent of any open chat screen.
  // Matchmaker-only — the user shell is untouched.
  late final MatchmakerRealtimePort _realtimePort;

  // FCM deep-linking (M4d). Confined to the shell — Moderator-only mount,
  // zero user-side impact. SignalR (4c) covers foreground live updates, so
  // foreground `onMessage` is intentionally NOT handled here.
  StreamSubscription<RemoteMessage>? _notifTapSub;

  @override
  void initState() {
    super.initState();
    _realtimePort = sl<MatchmakerRealtimePort>();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_safeConnect());
    // A new shell means a new session — start from the server's counts rather
    // than whatever the last account left behind.
    sl<BadgesCubit>().clear();
    unawaited(sl<BadgesCubit>().refresh());
    // Background-tap (app alive) + terminated/cold-start (launched by tap).
    _notifTapSub = FirebaseMessaging.onMessageOpenedApp.listen(_route);
    FirebaseMessaging.instance.getInitialMessage().then((m) {
      if (m != null) _route(m);
    });
  }

  @override
  void dispose() {
    unawaited(_notifTapSub?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_realtimePort.disconnect());
    super.dispose();
  }

  /// Route a tapped notification into the matchmaker tree. Defensive role
  /// guard (the shell is Moderator-only anyway). Parsing + audience guards
  /// live in [MatchmakerNotificationRouter]; this only navigates.
  void _route(RemoteMessage message) {
    if (!mounted) return;
    final role = sl<UserSessionCubit>().currentUser?.role;
    if ((role ?? '').toLowerCase() != 'moderator') return;
    _openFromNotification(MatchmakerNotificationRouter.parse(message.data));
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
      case OpenUserChat(:final conversationId, :final senderName):
        // Thin conversation: chat loads messages by id; senderName fills the
        // header. No route-arg change — satisfies the existing arg type.
        NavigationManager.navigateTo(
          context,
          RouteNames.matchmakerUserChat,
          arguments: MatchmakerConversation(
            userId: '',
            fullName: senderName,
            profileImageUrl: null,
            conversationId: conversationId,
            lastMessageAt: null,
            lastMessagePreview: null,
            unreadCount: 0,
          ),
        );
      case IgnoreDeepLink():
        break;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Keep-alive on pause (no teardown — simplest robust option). On
    // resume, re-establish only if the socket dropped while backgrounded;
    // the cases cubit catches up via its own reconnect listener.
    if (state == AppLifecycleState.resumed) {
      unawaited(sl<BadgesCubit>().refresh());
      if (_realtimePort.status == MatchmakerRealtimeStatus.disconnected) {
        unawaited(_safeConnect());
      }
    }
  }

  Future<void> _safeConnect() async {
    try {
      await _realtimePort.connect();
    } catch (_) {
      // The service already emitted `disconnected`; the rest of the shell
      // keeps working and a later resume retries.
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
      _visited.add(index);
      if (usersSubTab != null) _usersSubTab = usersSubTab;
    });
  }

  /// A tab body once it has been visited, else a zero-size placeholder so the
  /// tab's cubit (and its initial fetch) doesn't spin up until first visit.
  /// Unvisited tabs cost nothing; visited ones stay mounted, so they also need
  /// to be discarded and refetched when the app language changes.
  Widget _lazyTab(int index, Widget child) => _visited.contains(index)
      ? LocaleRebuildScope(child: child)
      : const SizedBox.shrink();

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
      // Owns the `/hubs/chat` session for the matchmaker shell. Separate from
      // [MatchmakerRealtimePort] above: that one carries case/conversation
      // events, this one carries the chat hub the shared conversation screen
      // reads — and, from batch 18, the badge events for every tab. Held here
      // rather than by the pushed chat screen so leaving a conversation can no
      // longer take the badges' transport down with it.
      child: ChatRealtimeHost(
        port: sl<ChatRealtimePort>(),
        accessTokenProvider: sl<ChatAccessTokenProvider>(),
        // Turns that session into live counts: assigns what the hub sends,
        // and refetches whatever a dropped socket missed.
        child: BadgesRealtimeHost(
          port: sl<ChatRealtimePort>(),
          badges: sl<BadgesCubit>(),
          child: BlocProvider<MatchmakerDashboardCubit>(
            create: (_) => sl<MatchmakerDashboardCubit>()..load(),
            child: MatchmakerHomeShellScope(
              openTab: _selectTab,
              openFromNotification: _openFromNotification,
              fromNotification: _fromNotification,
              returnToNotifications: _returnToNotifications,
              child: ScrollHidingNavScaffold(
                currentIndex: _currentTab,
                body: IndexedStack(
                  index: _currentTab,
                  children: [
                    _lazyTab(0, const MatchmakerDashboardTab()),
                    _lazyTab(
                      1,
                      MatchmakerUsersTab(
                        subTab: _usersSubTab,
                        onSubTabChanged: _changeUsersSubTab,
                      ),
                    ),
                    _lazyTab(2, const MatchmakerCasesTab()),
                    _lazyTab(3, const MatchmakerConversationsTab()),
                    _lazyTab(4, const MatchmakerExploreTab()),
                  ],
                ),
                navBuilder: (context) => MatchmakerBottomNav(
                  currentIndex: _currentTab,
                  onTap: _onNavTap,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
