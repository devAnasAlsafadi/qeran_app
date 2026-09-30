import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_nav.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/widgets/scroll_hiding_nav_scaffold.dart';
import 'package:qeran/features/badges/domain/entities/badge_counts.dart';
import 'package:qeran/features/badges/domain/entities/nav_badge_tabs.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/features/badges/presentation/widgets/badges_realtime_host.dart';
import 'package:qeran/features/chat/domain/ports/chat_realtime_port.dart';
import 'package:qeran/features/chat/presentation/blocs/my_matchmaker_cubit.dart';
import 'package:qeran/features/chat/presentation/screens/my_matchmaker_chat_page.dart';
import 'package:qeran/features/chat/presentation/widgets/chat_realtime_host.dart';
import 'package:qeran/features/community/presentation/screens/community_placeholder_screen.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_view.dart';
import 'package:qeran/features/home/presentation/home_push_routing.dart';
import 'package:qeran/features/home/presentation/home_refresh_policy.dart';
import 'package:qeran/features/home/presentation/home_shell_navigator.dart';
import 'package:qeran/features/home/presentation/home_shell_scope.dart';
import 'package:qeran/features/home/presentation/home_tab_switcher.dart';
import 'package:qeran/features/home/presentation/widgets/home_nav_items.dart';
import 'package:qeran/features/home/presentation/widgets/home_tab_stage.dart';
import 'package:qeran/features/home/presentation/widgets/shell_top_bar.dart';
import 'package:qeran/features/likes/presentation/screens/likes_screen.dart';
import 'package:qeran/features/notifications/presentation/routing/open_notifications.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/profile/presentation/screens/profile_screen.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';

/// Home shell: the top bar, the four tabs — Community (where it lands),
/// Suggestions, Interests, Profile — and the bottom navigation. Chat is not a
/// tab; the bar pushes it over the shell.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final HomeTabSwitcher _tabs = HomeTabSwitcher(
    vsync: this,
    initialTab: HomeShellNavigator.communityTab,
  );

  late final HomeShellNavigator _navigator = HomeShellNavigator(
    tabs: _tabs,
    markTabSeen: _markTabSeen,
    openInbox: () => Navigator.of(context).pushNamed(RouteNames.notifications),
    openChat: () => openMatchmakerChat(context),
  );

  late final HomePushRouting _push = HomePushRouting(
    onOpen: (link) {
      if (mounted) _navigator.openFromNotification(link);
    },
    onForegroundPush: () => unawaited(_refresh.onForegroundPush()),
  );

  /// Who the member's matchmaker is, for the top bar. The shell's own, closed
  /// with it.
  late final MyMatchmakerCubit _matchmaker = sl<MyMatchmakerCubit>();

  /// When the shell re-reads the state that lives above the tabs. It holds no
  /// state of its own: the cubits are app-scoped singletons, and the shell's.
  late final HomeRefreshPolicy _refresh = HomeRefreshPolicy(
    profileGate: sl<ProfileGateCubit>(),
    badges: sl<BadgesCubit>(),
    subscription: sl<CurrentSubscriptionCubit>(),
    matchmaker: _matchmaker,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabs.addListener(_rebuild);
    _navigator.addListener(_rebuild);
    unawaited(_refresh.onShellMount());
    _push.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _push.dispose();
    _navigator.dispose();
    _tabs.dispose();
    _matchmaker.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh.onResume());
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  /// No-ops when the tab has no badge, so a repeat visit costs nothing.
  void _markTabSeen(int index) {
    final key = NavBadgeTabs.user[index];
    if (key != null) unawaited(sl<BadgesCubit>().markSeen(key));
  }

  Widget _tabBody(int index) => switch (index) {
    HomeShellNavigator.communityTab => const CommunityPlaceholderScreen(),
    HomeShellNavigator.discoveryTab => const DiscoveryView(),
    HomeShellNavigator.likesTab => const LikesScreen(),
    HomeShellNavigator.profileTab => const ProfileScreen(),
    _ => const SizedBox.shrink(),
  };

  /// [context] is inside [HomeShellScope], which the inbox needs to hand back
  /// what the user taps there.
  Widget _body(BuildContext context, BadgeCounts badges) => Column(
    children: [
      ShellTopBar(
        badges: badges,
        onOpenChat: () => openMatchmakerChat(context),
        onOpenInbox: () => openNotifications(context),
      ),
      // The bar owns the status-bar inset, so the tabs start below it.
      Expanded(
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: HomeTabStage(tabs: _tabs, tabBuilder: _tabBody),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Only while the trail is live. Otherwise the system back keeps its
      // default meaning — pop the shell, or leave the app from the root.
      canPop: _navigator.backTrail == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _navigator.followBackTrail();
      },
      // Owns the `/hubs/chat` session for the whole user shell — the hub feeds
      // every tab, so it must not depend on the chat having been opened.
      child: ChatRealtimeHost(
        port: sl<ChatRealtimePort>(),
        accessTokenProvider: sl<ChatAccessTokenProvider>(),
        // Turns that session into live counts: assigns what the hub sends,
        // and refetches whatever a dropped socket missed.
        child: BadgesRealtimeHost(
          port: sl<ChatRealtimePort>(),
          badges: sl<BadgesCubit>(),
          child: HomeShellScope(
            openLikesTab: _navigator.openLikesTab,
            openProfileTab: _navigator.openProfileTab,
            openFromNotification: _navigator.openFromNotification,
            backTrail: _navigator.backTrail,
            followBackTrail: _navigator.followBackTrail,
            child: BlocProvider<MyMatchmakerCubit>.value(
              value: _matchmaker,
              child: BlocBuilder<BadgesCubit, BadgeCounts>(
                bloc: sl<BadgesCubit>(),
                builder: (context, badges) {
                  final items = buildHomeNavItems(context, badges);
                  return ScrollHidingNavScaffold(
                    currentIndex: _tabs.currentTab,
                    body: _body(context, badges),
                    navBuilder: (context) => QeranBottomNav(
                      items: items,
                      currentIndex: _tabs.currentTab,
                      onTap: _navigator.onNavTap,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
