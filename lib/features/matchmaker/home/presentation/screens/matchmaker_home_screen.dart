import 'package:flutter/material.dart';

import '../../../compatibility_cases/presentation/screens/matchmaker_cases_tab.dart';
import '../../../conversations/presentation/screens/matchmaker_conversations_tab.dart';
import '../../../dashboard/presentation/screens/matchmaker_dashboard_tab.dart';
import '../../../explore/presentation/screens/matchmaker_explore_tab.dart';
import '../../../users/presentation/screens/matchmaker_users_tab.dart';
import '../home_shell_scope.dart';
import '../widgets/matchmaker_bottom_nav.dart';

/// Matchmaker (role=Moderator) shell. Identity-cloned from the user
/// `HomeScreen`: same `extendBody: true`, same `QeranBottomNav`, same
/// scaffold rhythm. Only the items + bodies differ.
///
/// `IndexedStack` keeps each tab's state alive across switches so the
/// future cubits behind the dashboard / users / cases / conversations
/// / explore tabs don't lose pagination, search input, or scroll
/// position when the matchmaker hops between tabs.
class MatchmakerHomeScreen extends StatefulWidget {
  const MatchmakerHomeScreen({super.key});

  @override
  State<MatchmakerHomeScreen> createState() => _MatchmakerHomeScreenState();
}

class _MatchmakerHomeScreenState extends State<MatchmakerHomeScreen> {
  // Tab indices follow the IndexedStack order below.
  // 0 = Dashboard · 1 = Users · 2 = Cases · 3 = Conversations · 4 = Explore.
  int _currentTab = 0;

  void _selectTab(int index) {
    if (index == _currentTab) return;
    setState(() => _currentTab = index);
  }

  @override
  Widget build(BuildContext context) {
    return MatchmakerHomeShellScope(
      openTab: _selectTab,
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _currentTab,
          children: const [
            MatchmakerDashboardTab(),
            MatchmakerUsersTab(),
            MatchmakerCasesTab(),
            MatchmakerConversationsTab(),
            MatchmakerExploreTab(),
          ],
        ),
        bottomNavigationBar: MatchmakerBottomNav(
          currentIndex: _currentTab,
          onTap: _selectTab,
        ),
      ),
    );
  }
}
