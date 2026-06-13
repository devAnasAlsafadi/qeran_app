import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_nav.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/features/chat/presentation/screens/chat_entry_screen.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_view.dart';
import 'package:qeran/features/home/presentation/home_shell_scope.dart';
import 'package:qeran/features/likes/presentation/screens/likes_screen.dart';
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

  void _selectTab(int index) {
    if (index == _currentTab) return;
    setState(() => _currentTab = index);
  }

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
        body: _bodyFor(_currentTab),
        bottomNavigationBar: QeranBottomNav(
          items: items,
          currentIndex: _currentTab,
          onTap: _selectTab,
        ),
      ),
    );
  }

  Widget _bodyFor(int tab) {
    if (tab == _profileTabIndex) return const ProfileScreen();
    if (tab == _likesTabIndex) return const LikesScreen();
    if (tab == _messagesTabIndex) return const ChatEntryScreen();
    return const DiscoveryView(showTopBar: false);
  }
}
