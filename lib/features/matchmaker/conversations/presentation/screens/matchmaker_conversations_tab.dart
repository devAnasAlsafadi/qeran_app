import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_app_bar.dart';

/// Placeholder for the matchmaker conversations tab. M4 will replace
/// the body with sub-tabs (with-users / with-colleagues) backed by the
/// `/matchmaker/conversations/*` endpoints and the shared chat module.
class MatchmakerConversationsTab extends StatelessWidget {
  const MatchmakerConversationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: MatchmakerAppBar(
        title: LocaleKeys.matchmaker_nav_conversations.t(context),
      ),
      body: QeranEmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: LocaleKeys.matchmaker_empty_conversations_title.t(context),
        message: LocaleKeys.matchmaker_empty_conversations_message.t(context),
      ),
    );
  }
}
