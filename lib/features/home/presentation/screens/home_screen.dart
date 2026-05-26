import 'package:flutter/material.dart';
import 'package:qeran/features/chat/presentation/screens/chat_entry_screen.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_view.dart';
import 'package:qeran/features/home/presentation/home_shell_scope.dart';
import 'package:qeran/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:qeran/features/likes/presentation/screens/likes_screen.dart';
import 'package:qeran/features/profile/presentation/screens/profile_screen.dart';

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

  void _openMessagesTab() => _selectTab(_messagesTabIndex);

  @override
  Widget build(BuildContext context) {
    return HomeShellScope(
      openMessagesTab: _openMessagesTab,
      child: Scaffold(
        extendBody: true,
        // Discovery image bleeds to screen edges; the other screens own
        // their own SafeArea so the body stays free of outer padding
        // here. Scaffold inherits `QeranTheme.scaffoldBackgroundColor`
        // (cream canvas) per BRAND_DECISION.md.
        body: _bodyFor(_currentTab),
        bottomNavigationBar: HomeBottomNavBar(
          currentIndex: _currentTab,
          onTabSelected: _selectTab,
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
