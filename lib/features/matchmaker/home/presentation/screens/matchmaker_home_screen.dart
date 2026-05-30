import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../compatibility_cases/presentation/screens/matchmaker_cases_tab.dart';
import '../../../conversations/presentation/screens/matchmaker_conversations_tab.dart';
import '../../../dashboard/presentation/blocs/matchmaker_dashboard_cubit.dart';
import '../../../dashboard/presentation/screens/matchmaker_dashboard_tab.dart';
import '../../../explore/presentation/screens/matchmaker_explore_tab.dart';
import '../../../shared/domain/entities/matchmaker_realtime_status.dart';
import '../../../shared/domain/ports/matchmaker_realtime_port.dart';
import '../../../users/domain/entities/matchmaker_users_list.dart';
import '../../../users/presentation/screens/matchmaker_users_tab.dart';
import '../home_shell_scope.dart';
import '../widgets/matchmaker_bottom_nav.dart';

/// Matchmaker (role=Moderator) shell. Identity-cloned from the user
/// `HomeScreen`: same `extendBody: true`, same `QeranBottomNav`, same
/// scaffold rhythm. Only the items + bodies differ.
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

  // App-wide matchmaker realtime connection (M4c-1). Owned here so it
  // stays alive across all tabs, independent of any open chat screen.
  // Matchmaker-only — the user shell is untouched.
  late final MatchmakerRealtimePort _realtimePort;

  @override
  void initState() {
    super.initState();
    _realtimePort = sl<MatchmakerRealtimePort>();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_safeConnect());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_realtimePort.disconnect());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Keep-alive on pause (no teardown — simplest robust option). On
    // resume, re-establish only if the socket dropped while backgrounded;
    // the cases cubit catches up via its own reconnect listener.
    if (state == AppLifecycleState.resumed &&
        _realtimePort.status == MatchmakerRealtimeStatus.disconnected) {
      unawaited(_safeConnect());
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
      if (usersSubTab != null) _usersSubTab = usersSubTab;
    });
  }

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
        child: Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: _currentTab,
            children: [
              const MatchmakerDashboardTab(),
              MatchmakerUsersTab(
                subTab: _usersSubTab,
                onSubTabChanged: _changeUsersSubTab,
              ),
              const MatchmakerCasesTab(),
              const MatchmakerConversationsTab(),
              const MatchmakerExploreTab(),
            ],
          ),
          bottomNavigationBar: MatchmakerBottomNav(
            currentIndex: _currentTab,
            onTap: (i) => _selectTab(i),
          ),
        ),
      ),
    );
  }
}
