import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_nav.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/chat/presentation/screens/chat_entry_screen.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_view.dart';
import 'package:qeran/features/home/presentation/home_shell_scope.dart';
import 'package:qeran/features/likes/presentation/screens/likes_screen.dart';
import 'package:qeran/features/notifications/presentation/blocs/notification_badge_cubit.dart';
import 'package:qeran/features/notifications/presentation/routing/notification_deep_link.dart';
import 'package:qeran/features/profile/presentation/screens/profile_screen.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Home shell. Hosts the Discovery deck (image bleeds to screen edges
/// per Figma, with filter + notification bell as overlays on the image
/// itself) and the bottom navigation.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _discoveryTabIndex = 0;
  static const int _likesTabIndex = 1;
  static const int _messagesTabIndex = 2;
  static const int _profileTabIndex = 3;
  int _currentTab = _discoveryTabIndex;

  // Tabs mount lazily: an index enters this set the first time it is shown and
  // stays (IndexedStack keeps it alive after), so each tab fetches on first
  // visit and never re-fetches on later switches. Seeded with the tab shown at
  // shell entry so only that one loads on cold start.
  final Set<int> _visited = {_discoveryTabIndex};

  // FCM deep-linking. Confined to the shell — mirrors the matchmaker shell
  // (no main.dart bootstrap changes). Role-guarded so a matchmaker-targeted
  // push never acts on the user tree. The user app has no SignalR, so the
  // foreground stream refreshes the bell badge here (live-update equivalent).
  StreamSubscription<RemoteMessage>? _notifTapSub;
  StreamSubscription<RemoteMessage>? _notifForegroundSub;

  @override
  void initState() {
    super.initState();
    // Background-tap (app alive) + terminated/cold-start (launched by tap).
    _notifTapSub = FirebaseMessaging.onMessageOpenedApp.listen(_route);
    FirebaseMessaging.instance.getInitialMessage().then((m) {
      if (m != null) _route(m);
    });
    // Foreground push → refresh the unread bell dot (no auto-navigation).
    _notifForegroundSub = FirebaseMessaging.onMessage.listen((_) {
      unawaited(sl<NotificationBadgeCubit>().refresh());
    });
  }

  @override
  void dispose() {
    unawaited(_notifTapSub?.cancel());
    unawaited(_notifForegroundSub?.cancel());
    super.dispose();
  }

  /// Route a tapped notification into a bottom-nav tab. Defensive role guard:
  /// only the regular user shell acts (a Moderator push routes elsewhere).
  /// Non-actionable payloads ([NoDeepLink]) do nothing.
  void _route(RemoteMessage message) {
    if (!mounted) return;
    final role = sl<UserSessionCubit>().currentUser?.role;
    if ((role ?? '').toLowerCase() == 'moderator') return;
    switch (NotificationDeepLinkRouter.resolveData(message.data)) {
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

  void _selectTab(int index) {
    if (index == _currentTab) return;
    setState(() {
      _currentTab = index;
      _visited.add(index);
    });
  }

  /// A tab body once it has been visited, else a zero-size placeholder so the
  /// tab's cubit (and its initial fetch) doesn't spin up until first visit.
  Widget _lazyTab(int index, Widget child) =>
      _visited.contains(index) ? child : const SizedBox.shrink();

  void _openLikesTab() => _selectTab(_likesTabIndex);
  void _openMessagesTab() => _selectTab(_messagesTabIndex);
  void _openProfileTab() => _selectTab(_profileTabIndex);

  @override
  Widget build(BuildContext context) {
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
      ),
      QeranNavItem(
        outlineIcon: Icons.chat_bubble_outline_rounded,
        filledIcon: Icons.chat_bubble_rounded,
        label: LocaleKeys.home_nav_messages.t(context),
      ),
      QeranNavItem(
        outlineIcon: Icons.person_outline_rounded,
        filledIcon: Icons.person_rounded,
        label: LocaleKeys.home_nav_profile.t(context),
      ),
    ];
    return HomeShellScope(
      openLikesTab: _openLikesTab,
      openMessagesTab: _openMessagesTab,
      openProfileTab: _openProfileTab,
      child: Scaffold(
        extendBody: true,
        // IndexedStack keeps each tab's state alive across switches —
        // mirrors the matchmaker shell. This kills the refetch spinner on
        // every tab change AND keeps the Discovery deck (and its animation
        // controllers) mounted, so a rapid like/skip mash that overlaps a
        // tab switch can't orphan an in-flight animation. Trade-off: all
        // four tabs build once on shell mount. Order = tab-index order
        // (0 discovery · 1 likes · 2 messages · 3 profile).
        body: IndexedStack(
          index: _currentTab,
          children: [
            _lazyTab(_discoveryTabIndex, const DiscoveryView(showTopBar: false)),
            _lazyTab(_likesTabIndex, const LikesScreen()),
            _lazyTab(_messagesTabIndex, const ChatEntryScreen()),
            _lazyTab(_profileTabIndex, const ProfileScreen()),
          ],
        ),
        bottomNavigationBar: QeranBottomNav(
          items: items,
          currentIndex: _currentTab,
          onTap: _selectTab,
        ),
      ),
    );
  }
}
