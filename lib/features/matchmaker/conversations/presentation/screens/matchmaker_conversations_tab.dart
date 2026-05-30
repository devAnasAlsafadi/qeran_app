import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_app_bar.dart';
import '../../../shared/presentation/widgets/matchmaker_segmented_tabs.dart';
import '../widgets/matchmaker_user_conversations_list.dart';

/// Matchmaker conversations tab (M4a). Two segments: مستخدمون — the real
/// paginated users-conversations list — and الزميلات, a placeholder until the
/// colleague-conversation shape is finalised. An IndexedStack keeps the users
/// list's pagination + scroll alive across segment switches.
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
                children: const [
                  MatchmakerUserConversationsList(),
                  _ColleaguesPlaceholder(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Colleagues segment — placeholder only in 4a. The real colleague
/// conversations list lands once the backend exposes a stable item shape.
class _ColleaguesPlaceholder extends StatelessWidget {
  const _ColleaguesPlaceholder();

  @override
  Widget build(BuildContext context) {
    return QeranEmptyState(
      icon: Icons.groups_2_outlined,
      title:
          LocaleKeys.matchmaker_conversations_colleagues_empty_title.t(context),
      message: LocaleKeys.matchmaker_conversations_colleagues_empty_message
          .t(context),
    );
  }
}
