import 'package:flutter/widgets.dart';

import '../../../../../core/widgets/locale_rebuild_scope.dart';
import '../../../compatibility_cases/presentation/screens/matchmaker_cases_tab.dart';
import '../../../conversations/presentation/screens/matchmaker_conversations_tab.dart';
import '../../../dashboard/presentation/screens/matchmaker_dashboard_tab.dart';
import '../../../explore/presentation/screens/matchmaker_explore_tab.dart';
import '../../../users/domain/entities/matchmaker_users_list.dart';
import '../../../users/presentation/screens/matchmaker_users_tab.dart';

/// Her five tabs. `IndexedStack` keeps each tab's state alive across
/// switches. Indices: 0 = Dashboard · 1 = Users · 2 = Cases ·
/// 3 = Conversations · 4 = Explore.
class MatchmakerShellTabs extends StatefulWidget {
  const MatchmakerShellTabs({
    super.key,
    required this.currentIndex,
    required this.usersSubTab,
    required this.onUsersSubTabChanged,
  });

  final int currentIndex;
  final MatchmakerUsersList usersSubTab;
  final ValueChanged<MatchmakerUsersList> onUsersSubTabChanged;

  @override
  State<MatchmakerShellTabs> createState() => _MatchmakerShellTabsState();
}

class _MatchmakerShellTabsState extends State<MatchmakerShellTabs> {
  // Tabs mount lazily: an index enters this set the first time it is shown and
  // stays (IndexedStack keeps it alive after), so each tab fetches on first
  // visit and never re-fetches on later switches.
  late final Set<int> _visited = {widget.currentIndex};

  @override
  void didUpdateWidget(MatchmakerShellTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visited.add(widget.currentIndex);
  }

  /// A tab body once it has been visited, else a zero-size placeholder so the
  /// tab's cubit (and its initial fetch) doesn't spin up until first visit.
  /// Unvisited tabs cost nothing; visited ones stay mounted, so they also need
  /// to be discarded and refetched when the app language changes.
  Widget _lazyTab(int index, Widget child) => _visited.contains(index)
      ? LocaleRebuildScope(child: child)
      : const SizedBox.shrink();

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.currentIndex,
      children: [
        _lazyTab(0, const MatchmakerDashboardTab()),
        _lazyTab(
          1,
          MatchmakerUsersTab(
            subTab: widget.usersSubTab,
            onSubTabChanged: widget.onUsersSubTabChanged,
          ),
        ),
        _lazyTab(2, const MatchmakerCasesTab()),
        _lazyTab(3, const MatchmakerConversationsTab()),
        _lazyTab(4, const MatchmakerExploreTab()),
      ],
    );
  }
}
