import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../colleagues/presentation/widgets/matchmaker_colleague_conversations_list.dart';
import '../../../shared/presentation/widgets/matchmaker_app_bar.dart';
import '../../../shared/presentation/widgets/matchmaker_segmented_tabs.dart';
import '../widgets/matchmaker_user_conversations_list.dart';

/// Matchmaker conversations tab (M4a / S2b). Two segments: مستخدمون — the
/// paginated users-conversations list — and الزميلات, the colleague-
/// conversations list. An IndexedStack keeps each list's pagination + scroll
/// alive across segment switches. The colleagues segment also shows a "new
/// conversation" FAB that opens the colleague directory to start a chat.
class MatchmakerConversationsTab extends StatefulWidget {
  const MatchmakerConversationsTab({super.key});

  @override
  State<MatchmakerConversationsTab> createState() =>
      _MatchmakerConversationsTabState();
}

class _MatchmakerConversationsTabState
    extends State<MatchmakerConversationsTab> {
  // 0 = Users · 1 = Colleagues.
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: MatchmakerAppBar(
        title: LocaleKeys.matchmaker_nav_conversations.t(context),
      ),
      floatingActionButton: _segment == 1 ? const _NewColleagueChatFab() : null,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            MatchmakerSegmentedTabs(
              activeIndex: _segment,
              onChanged: (i) => setState(() => _segment = i),
              segments: const [
                MatchmakerSegment(
                  labelKey: LocaleKeys.matchmaker_conversations_segment_users,
                ),
                MatchmakerSegment(
                  labelKey:
                      LocaleKeys.matchmaker_conversations_segment_colleagues,
                ),
              ],
            ),
            Expanded(
              child: IndexedStack(
                index: _segment,
                sizing: StackFit.expand,
                children: const [
                  MatchmakerUserConversationsList(),
                  MatchmakerColleagueConversationsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gold "new conversation" FAB — opens the colleague directory to start a chat.
/// Placement chosen here (Figma not explicit): visible only on the colleagues
/// segment, painted with DS tokens (gold surface, wine icon).
class _NewColleagueChatFab extends StatelessWidget {
  const _NewColleagueChatFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: QeranColors.gold,
      foregroundColor: QeranColors.wine,
      elevation: 2,
      tooltip: LocaleKeys.matchmaker_conversations_colleagues_new.t(context),
      onPressed: () =>
          Navigator.of(context).pushNamed(RouteNames.matchmakerColleaguesDirectory),
      child: const Icon(Icons.edit_outlined),
    );
  }
}
