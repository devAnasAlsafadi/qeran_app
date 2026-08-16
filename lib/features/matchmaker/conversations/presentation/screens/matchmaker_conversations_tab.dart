import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../colleagues/presentation/widgets/matchmaker_colleague_conversations_list.dart';
import '../../../shared/presentation/widgets/matchmaker_app_bar.dart';
import '../../../shared/presentation/widgets/matchmaker_segmented_tabs.dart';
import '../widgets/matchmaker_user_conversations_list.dart';

/// Matchmaker conversations tab (M4a / S2b). Two segments: مستخدمون — the
/// paginated users-conversations list — and الزميلات, the colleague-
/// conversations list. An IndexedStack keeps each list's pagination + scroll
/// alive across segment switches.
///
/// Both segments are read surfaces over threads that already exist. There is
/// deliberately no "start a new colleague chat" affordance: a browsable roster
/// of colleagues was built and removed as unwanted — colleague conversations
/// begin from a shared context (a case, an explore row, a user profile), which
/// is where the open-chat entry points live.
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
