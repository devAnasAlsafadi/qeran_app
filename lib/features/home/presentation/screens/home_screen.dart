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
import 'package:qeran/features/chat/presentation/screens/chat_entry_screen.dart';
import 'package:qeran/features/chat/presentation/widgets/chat_realtime_host.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_view.dart';
import 'package:qeran/features/home/presentation/home_push_routing.dart';
import 'package:qeran/features/home/presentation/home_refresh_policy.dart';
import 'package:qeran/features/home/presentation/home_shell_navigator.dart';
import 'package:qeran/features/home/presentation/home_shell_scope.dart';
import 'package:qeran/features/home/presentation/home_tab_switcher.dart';
import 'package:qeran/features/home/presentation/widgets/home_nav_items.dart';
import 'package:qeran/features/home/presentation/widgets/home_tab_stage.dart';
import 'package:qeran/features/likes/presentation/screens/likes_screen.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/profile/presentation/screens/profile_screen.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';

/// Home shell. Hosts the Discovery deck (with its own top bar — title +
/// filter + notification bell) and the bottom navigation.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final HomeTabSwitcher _tabs = HomeTabSwitcher(
    vsync: this,
    initialTab: HomeShellNavigator.discoveryTab,
  );

  late final HomeShellNavigator _navigator = HomeShellNavigator(
    tabs: _tabs,
    markTabSeen: _markTabSeen,
    openInbox: () => Navigator.of(context).pushNamed(RouteNames.notifications),
  );

  late final HomePushRouting _push = HomePushRouting(
    onOpen: (link) {
      if (mounted) _navigator.openFromNotification(link);
    },
    onForegroundPush: () => unawaited(_refresh.onForegroundPush()),
  );

  /// When the shell re-reads the state that lives above the tabs. Every
  /// dependency is an app-scoped singleton, so this holds no state of its own.
  late final HomeRefreshPolicy _refresh = HomeRefreshPolicy(
    profileGate: sl<ProfileGateCubit>(),
    badges: sl<BadgesCubit>(),
    subscription: sl<CurrentSubscriptionCubit>(),
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
    HomeShellNavigator.discoveryTab => const DiscoveryView(),
    HomeShellNavigator.likesTab => const LikesScreen(),
    // The Messages tab already takes an onBack for its pushed copy; reached
    // from a notification it needs the same control. (Only the system-push path
    // lands here — a chat row tapped in the inbox pushes over it instead.)
    HomeShellNavigator.messagesTab => ChatEntryScreen(
      key: ValueKey<String>('chat-entry-${_navigator.messagesRefreshEpoch}'),
      onBack: _navigator.backTrail == null ? null : _navigator.followBackTrail,
    ),
    HomeShellNavigator.profileTab => const ProfileScreen(),
    _ => const SizedBox.shrink(),
  };

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
      // every tab, so it must not depend on Messages having been opened.
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
            openMessagesTab: _navigator.openMessagesTab,
            openProfileTab: _navigator.openProfileTab,
            openFromNotification: _navigator.openFromNotification,
            backTrail: _navigator.backTrail,
            followBackTrail: _navigator.followBackTrail,
            child: BlocBuilder<BadgesCubit, BadgeCounts>(
              bloc: sl<BadgesCubit>(),
              builder: (context, badges) {
                final items = buildHomeNavItems(context, badges);
                return ScrollHidingNavScaffold(
                  currentIndex: _tabs.currentTab,
                  body: HomeTabStage(tabs: _tabs, tabBuilder: _tabBody),
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
    );
  }
}
