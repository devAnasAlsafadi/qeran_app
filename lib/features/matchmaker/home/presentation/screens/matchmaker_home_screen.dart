import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';

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
import '../../../notifications/presentation/blocs/matchmaker_notification_badge_cubit.dart';
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
    // Prime the bell badge (unread = total − last-seen). Silent on failure.
    unawaited(sl<MatchmakerNotificationBadgeCubit>().refresh());
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
    switch (MatchmakerNotificationRouter.parse(message.data)) {
      case OpenCases():
        _selectTab(2); // Cases tab — the shell owns selection (no route change).
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
      unawaited(sl<MatchmakerNotificationBadgeCubit>().refresh());
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

  void _selectTab(int index, {MatchmakerUsersList? usersSubTab}) {
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

  void _changeUsersSubTab(MatchmakerUsersList sub) {
    if (sub == _usersSubTab) return;
    setState(() => _usersSubTab = sub);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MatchmakerDashboardCubit>(
      create: (_) => sl<MatchmakerDashboardCubit>()..load(),
      child: MatchmakerHomeShellScope(
        openTab: _selectTab,
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
            onTap: (i) => _selectTab(i),
          ),
        ),
      ),
    );
  }
}
